import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    markers: Array,
    zoom: Number,
    center: Array
  }

  connect() {
    if (!window.L) {
      console.warn("Leaflet could not be found on window. Map aborted.")
      return
    }

    const fallbackCenter = this.hasCenterValue ? this.centerValue : [-34.6037, -58.3816]
    const zoomLevel = this.hasZoomValue ? this.zoomValue : 5

    this.map = L.map(this.element).setView(fallbackCenter, zoomLevel)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; <a href='https://www.openstreetmap.org/copyright'>OpenStreetMap</a> contributors"
    }).addTo(this.map)

    this.markerInstances = new Map()

    if (!this.hasMarkersValue || this.markersValue.length === 0) {
      return
    }

    const bounds = []

    this.markersValue.forEach((marker) => {
      if (!marker.latitude || !marker.longitude) return

      const coordinates = [marker.latitude, marker.longitude]
      bounds.push(coordinates)

      const markerInstance = L.marker(coordinates)
        .addTo(this.map)
        .bindPopup(`<strong>${marker.name}</strong><br>${marker.address}`)

      if (marker.id) {
        this.markerInstances.set(marker.id.toString(), markerInstance)
      }
    })

    if (bounds.length > 1) {
      this.map.fitBounds(bounds, { padding: [25, 25] })
    } else {
      this.map.setView(bounds[0], zoomLevel)
    }
  }

  focusMarker(event) {
    if (event.type === "keypress" && event.key !== "Enter" && event.key !== " ") {
      return
    }

    event.preventDefault()

    const markerId = event.params.markerId || event.currentTarget.dataset.mapMarkerIdParam
    if (!markerId || !this.markerInstances.has(markerId.toString())) return

    const marker = this.markerInstances.get(markerId.toString())
    const focusZoom = Math.max((this.hasZoomValue ? this.zoomValue : 5) + 2, 11)

    this.map.setView(marker.getLatLng(), focusZoom, { animate: true })
    marker.openPopup()
  }
}
