import { Controller } from "stimulus"

export default class extends Controller {
  filter() {
    Array.from(document.querySelector("#books").children).forEach((element, idx) => {
      element.style.display = "block"
    })

    let selectedPub = document.querySelector(".pubfilter").value
    if(selectedPub) { document.querySelector("#search_box").value = "" }
    this.filterPublishers(selectedPub)
    document.querySelector("#title_sort").style.display = "none"
    document.querySelector("#pub_sort").style.display = "block"
  }

  // Private

  filterPublishers(publisher) {
    document.querySelector(".about").style.display = "none"
    document.querySelector("#fade").style.display = "none"
    document.querySelector("#pub_sort").style.display = "block"
    document.querySelector("#title_sort").style.display = "none"

    if(publisher === "Show All") {
      Array.from(document.querySelector("#books").children).forEach((element, idx) => {
        element.style.display = "block"
      })
      document.querySelector("#sort").style.display = "block"
      document.querySelector("#nav_info").style.display = "none"
    } else {
      Array.from(document.querySelector("#books").children).forEach((book) => {
        book.style.display = "none"
      })

      var allBooks = Array.from(document.querySelectorAll("article p[itemprop='publisher']"))
      var matchingBooks = []
      allBooks.forEach((candidate) => {
        if(candidate.textContent == publisher)
          matchingBooks.push(candidate)
      })
      var numberFound = matchingBooks.length

      document.querySelector("#sort").style.display = "none"
      matchingBooks.forEach((element) => {
        element.closest("article").style.display = "block"
      })
      if(numberFound === 1) {
        var bookStr = "book"
      } else {
        var bookStr = "books"
      }
      document.querySelector("#nav_info").innerHTML = "Found <strong>" + matchingBooks.length + "</strong> " + bookStr + " for <strong>" + publisher + "</strong>"
      document.querySelector("#nav_info").style.display = "block"
    }
  }
}
