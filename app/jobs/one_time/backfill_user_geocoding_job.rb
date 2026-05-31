class OneTime::BackfillUserGeocodingJob < ApplicationJob
  queue_as :literally_whenever

  def scope = User.where(geocoded_country: nil).where.not(ip_address: [ nil, "" ])

  def perform
    copied_count = copy_from_matching_rsvps
    enqueued_count = enqueue_missing_geocoding

    Rails.logger.info "[BackfillUserGeocoding] Copied #{copied_count} users from RSVPs; enqueued #{enqueued_count} geocode jobs"
  end

  private

  def copy_from_matching_rsvps
    count = 0

    User.where.not(email: [ nil, "" ]).find_each do |user|
      rsvp = matching_rsvp_for(user)
      next unless rsvp

      changes = missing_signup_geo_attrs(user, rsvp)
      next if changes.empty?

      user.update_columns(changes)
      count += 1
    end

    count
  end

  def matching_rsvp_for(user)
    Rsvp.where("LOWER(email) = ?", user.email.downcase)
        .where.not(ip_address: [ nil, "" ])
        .order(:created_at)
        .first
  end

  def missing_signup_geo_attrs(user, rsvp)
    {
      ip_address: rsvp.ip_address,
      user_agent: rsvp.user_agent,
      geocoded_lat: rsvp.geocoded_lat,
      geocoded_lon: rsvp.geocoded_lon,
      geocoded_country: rsvp.geocoded_country,
      geocoded_subdivision: rsvp.geocoded_subdivision
    }.select { |attribute, value| user.public_send(attribute).blank? && value.present? }
  end

  def enqueue_missing_geocoding
    count = 0
    scope.find_each do |user|
      UserGeocodeJob.perform_later(user.id)
      count += 1
    end

    count
  end
end
