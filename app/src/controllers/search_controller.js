import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["term"]

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

  search_books() {
    this.clear()

    const allBooks = Array.from(document.querySelector('#books').children)
    const rawTerm = this.termTarget.value
    const searchOperator = this.getSearchOperator(rawTerm)
    const searchTerm = rawTerm.replace(searchOperator + ':', '').trim()

    let matchingAuthors = []
    let matchingTitles = []
    let matchingBooks = []

    if(!searchOperator || searchOperator == 'author') {
      matchingAuthors = this.searchAuthors(searchTerm)
    }

    if(!searchOperator || searchOperator == 'title') {
      matchingTitles = this.searchTitles(searchTerm)
    }

    if (matchingAuthors)
      matchingAuthors = Array.from(new Set(matchingAuthors))
      matchingBooks = matchingBooks.concat(matchingAuthors)

    if (matchingTitles)
      matchingBooks = matchingBooks.concat(matchingTitles)

    if (matchingBooks.length > 0) sortElements(allBooks, titleSort)

    matchingBooks.forEach((element) => {
      element.style.display = "block"
    })

    const numberFound = matchingBooks.length
    if(numberFound === 1) {
      var bookStr = "book"
    } else {
      var bookStr = "books"
    }

    document.querySelector('#nav_info').innerHTML = 'Found <strong>' + numberFound + '</strong> ' + bookStr + ' matching "<strong>' + searchTerm + '</strong>"'
    document.querySelector('#nav_info').style.display = 'block'
  }

  // Private

  searchAuthors(term) {
    let matchingAuthors = []
    const allAuthors = Array.from(document.querySelectorAll("article ul[class='authors']"))

    allAuthors.forEach((author) => {
      if(author.textContent.toLowerCase().includes(term.toLowerCase()))
        matchingAuthors.push(author.closest("article"))
    })

    return matchingAuthors
  }

  searchTitles(term) {
    let matchingTitles = []
    const allTitles = Array.from(document.querySelectorAll("a[itemprop='name']"))

    allTitles.forEach((title) => {
      if(title.textContent.toLowerCase().includes(term.toLowerCase()))
        matchingTitles.push(title.closest("article"))
    })

    return matchingTitles
  }

  getSearchOperator(query) {
    const validOperators = ['title', 'author']
    const candidate = query.split(':')[0]
    if(validOperators.includes(candidate))
      return candidate
  }

  clear() {
    document.querySelector('.about').style.display = "none"
    document.querySelector('#fade').style.display = "none"
    document.querySelector('.pubfilter').selectedIndex = -1
    document.querySelector('#title_sort').style.display = "none"
    document.querySelector('#pub_sort').style.display = "none"
    document.querySelector('#nav_info').style.display = "none"
    Array.from(document.querySelector('#books').children).forEach((element, idx) => {
      element.style.display = "none"
    })
  }
}
