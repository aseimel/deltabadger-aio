import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="broadcast--on-connect"
export default class extends Controller {
  static values = { method: String, methodArgs: Object };

  connect() {
    this.attempts = 0;
    this.maxAttempts = 100; // 100 × 100ms = 10s

    this.checkConnectionInterval = setInterval(() => {
      this.attempts++;
      if (this.#isConnectedToTurboStreamsChannel()) {
        this.#triggerBroadcast();
        clearInterval(this.checkConnectionInterval);
      } else if (this.attempts >= this.maxAttempts) {
        clearInterval(this.checkConnectionInterval);
        this.#clearAllSpinners();
      }
    }, 100);
  }

  #triggerBroadcast() {
    fetch(`/broadcasts/${this.methodValue}`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(this.methodArgsValue),
    }).catch(() => this.#clearAllSpinners());

    // Safety net: clear any remaining spinners after 30s
    setTimeout(() => this.#clearAllSpinners(), 30000);
  }

  #clearAllSpinners() {
    this.element.querySelectorAll('.loader--small').forEach(loader => {
      loader.remove();
    });
  }

  #isConnectedToTurboStreamsChannel() {
    if (!window.Turbo) {
      return false;
    }

    // Check for Turbo::StreamsChannel subscriptions
    const turboStreamElements = document.querySelectorAll(
      'turbo-cable-stream-source[channel="Turbo::StreamsChannel"][connected]'
    );

    return turboStreamElements.length > 0;
  }
}
