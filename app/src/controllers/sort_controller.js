import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "article" ]

  initialize() {
    document.querySelector('h1.fallback').style.color = "#fff"
    document.querySelector('header').style.height = "110"
    document.querySelector('#nav_info').style.display = "block"
    document.querySelector('#filters').style.display = "block"
    document.querySelector('.pubfilter').selectedIndex = -1
    document.querySelector('#pub_sort').style.display = "block"
    document.querySelector('#search').style.display = "block"
    document.querySelector('#search_box').textContent = ""
    document.querySelector('#fade').style.display = "none"
  }

  publisher_sort() {
    document.querySelector('.about').style.display = "none"
    document.querySelector('#fade').style.display = "none"
    sortElements(this.articleTargets, publisherSort)
    document.querySelector('#pub_sort').style.display = "none"
    document.querySelector('#title_sort').style.display = "block"
  }

  title_sort() {
    document.querySelector('.about').style.display = "none"
    document.querySelector('#fade').style.display = "none"
    sortElements(this.articleTargets, titleSort)
    document.querySelector('#title_sort').style.display = "none"
    document.querySelector('#pub_sort').style.display = "block"
  }
}
