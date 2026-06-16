import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["link"];

  connect() {
    this.ticking = false;
    this.onScroll = () => {
      if (this.ticking) return;
      this.ticking = true;
      requestAnimationFrame(() => {
        this.updateActive();
        this.ticking = false;
      });
    };
    window.addEventListener("scroll", this.onScroll, { passive: true });
    this.sections = [...document.querySelectorAll(".ship-monitor__section[id]")];
    this.updateActive();
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll);
  }

  scrollTo(e) {
    e.preventDefault();
    document.querySelector(e.currentTarget.getAttribute("href"))
      ?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  updateActive() {
    const threshold = window.scrollY + window.innerHeight * 0.35;
    let active = this.sections[0];
    for (const section of this.sections) {
      if (section.offsetTop <= threshold) active = section;
    }
    if (!active) return;
    this.linkTargets.forEach((link) => {
      link.classList.toggle("is-active", link.getAttribute("href") === `#${active.id}`);
    });
  }
}
