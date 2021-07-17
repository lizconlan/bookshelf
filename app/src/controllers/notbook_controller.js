import { Controller } from "stimulus"

export default class extends Controller {
  close_books() {
    document.querySelectorAll('.about').forEach((element, idx) => {
      element.style.display = "none"
    })
    document.querySelector('#fade').style.display = "none"
  }
}
