import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["panel", "tabset", "button", "content"]

  reveal_info() {
    document.querySelector('#fade').style.display = "block"
    this.panelTarget.style.display = "block"
    if(this.hasTabsetTarget) {
      this.contentTargets.forEach((element, idx) => {
        element.style.display = ""
      })
      this.contentTarget.style.display = "block"
      this.buttonTarget.classList.add("selected")
    }
  }

  show_tab(evt) {
    let idx = evt.target.dataset.idx

    // unselect all buttons
    this.buttonTargets.forEach((element) => {
      element.classList.remove("selected")
    })
    this.buttonTargets[idx].classList.add("selected")

    // hide open panels
    this.contentTargets.forEach((element) => {
      element.style.display = ""
    })
    this.contentTargets[idx].style.display = "block"
  }
}
