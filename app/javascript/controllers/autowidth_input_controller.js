import { Controller } from "@hotwired/stimulus"

// Automatically adjusts the width of an input element based on its content length using a mirror element for precise calculation.
// Connects to data-controller="autowidth-input"
export default class extends Controller {

  connect() {
    this.resize = this.resize.bind(this)
    this.minWidthValue = this.element.style.width || "0px";
    this.#createMirrorElement()
    this.#transferStyles()
    this.resize()
    this.element.addEventListener('input', this.resize)
  }

  disconnect() {
    this.element.removeEventListener('input', this.resize)
  }

  resize() {
    const text = this.element.value || this.element.placeholder || ''
    this.mirrorElement.textContent = text;
    const mirrorWidth = this.mirrorElement.offsetWidth;

    // Shrink to measure true content width via the input's own rendering
    this.element.style.width = '0';
    const scrollWidth = this.element.scrollWidth;

    // Use the wider of the two measurements plus a small buffer for rounding
    const finalWidth = Math.max(mirrorWidth, scrollWidth) + 4;
    this.element.style.width = `calc(max(${this.minWidthValue}, ${finalWidth}px))`;
  }

  #createMirrorElement() {
    this.mirrorElement = document.createElement('span')
    // Apply styles to make it invisible but measurable
    Object.assign(this.mirrorElement.style, {
      position: 'absolute',
      visibility: 'hidden',
      height: 'auto',
      width: 'auto',
      whiteSpace: 'pre', // Use 'pre' to respect spaces and prevent wrapping
      top: '-9999px',      // Position off-screen
      left: '-9999px'
    })
    document.body.appendChild(this.mirrorElement)
  }

  #transferStyles() {
    const computedStyle = window.getComputedStyle(this.element)
    // List of CSS properties that affect horizontal size
    const stylesToCopy = [
      'fontSize', 'fontFamily', 'fontWeight', 'fontStyle',
      'letterSpacing', 'textTransform', 'wordSpacing',
      'paddingLeft', 'paddingRight',
      'borderLeftWidth', 'borderRightWidth',
      // Add any other relevant style properties if needed
    ];

    stylesToCopy.forEach(prop => {
      this.mirrorElement.style[prop] = computedStyle[prop]
    })
  }
}