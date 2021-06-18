(() => {
  const application = Stimulus.Application.start()

  let sortElements = function(items, sorter) {
    var targetElement = items[0].parentElement

    Array.from(targetElement.children).forEach(node=>targetElement.removeChild(node))
    items.sort(sorter).forEach(node=>targetElement.appendChild(node))
  }

  let titleSort = function(a, b) {
    let title_a = Array.from(a.querySelectorAll("h2"))[0].textContent.trim()
    let sort_key_a = title_a.trim().replace(/^(The )|(A )/, "")

    let title_b = Array.from(b.querySelectorAll("h2"))[0].textContent.trim()
    let sort_key_b = title_b.trim().replace(/^(The )|(A )/, "")

    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase())
  }

  let publisherSort = function(a, b){
    let pub_a = Array.from(a.querySelectorAll("p[itemprop='publisher']"))[0].textContent.trim()
    let title_a = Array.from(a.querySelectorAll("h2"))[0].textContent.trim()
    let sort_key_a = pub_a.trim() + "__" + title_a.trim().replace(/^(The )|(A )/, "")

    let pub_b = Array.from(b.querySelectorAll("p[itemprop='publisher']"))[0].textContent.trim()
    let title_b = Array.from(b.querySelectorAll("h2"))[0].textContent.trim()
    let sort_key_b = pub_b.trim() + "__" + title_b.trim().replace(/^(The )|(A )/, "")

    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase())
  }

  application.register("start", class extends Stimulus.Controller {
    initialize() {
      document.querySelector('h1.fallback').style.color = "#fff"
      document.querySelector("header").style.height = "110"
      document.querySelector("#nav_info").style.display = "block"
      document.querySelector("#filters").style.display = "block"
      document.querySelector(".pubfilter").selectedElement = 0
      document.querySelector("#pub_sort").style.display = "block"
      document.querySelector("#search").style.display = "block"
      document.querySelector("#search_box").value = ""
      document.querySelector("#fade").style.display = ""
      document.querySelectorAll("img[itemprop='image']").forEach((element, idx) => {
        element.style.cursor = "pointer"
      })
    }
  })

  application.register("book", class extends Stimulus.Controller {
    static get targets() {
      return [ "panel", "tabset", "button", "content" ]
    }

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
  })

  application.register("filter", class extends Stimulus.Controller {
    filter() {
      let selectedPub = document.querySelector(".pubfilter").value
      if(selectedPub) { document.querySelector("#search_box").value = "" }
      this._filterPublishers(selectedPub)
      document.querySelector("#title_sort").style.display = ""
      document.querySelector("#pub_sort").style.display = "block"
    }

    _filterPublishers(publisher) {
      document.querySelector(".about").style.display = ""
      document.querySelector("#fade").style.display = ""
      document.querySelector("#pub_sort").style.display = "block"
      document.querySelector("#title_sort").style.display = ""

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
  })

  application.register("notbook", class extends Stimulus.Controller {
    close_books() {
      document.querySelectorAll('.about').forEach((element, idx) => {
        element.style.display = "none"
      })
      document.querySelector('#fade').style.display = "none"
    }
  })

  application.register("search", class extends Stimulus.Controller {
    static targets = ["term"]

    search_books() {
      this._clear()

      let matchingAuthors = []
      let matchingTitles = []
      let matchingBooks = []

      let rawTerm = this.termTarget.value
      let searchOperator = this._getSearchOperator(rawTerm)
      let searchTerm = rawTerm.replace(searchOperator + ':', '').trim()

      if(!searchOperator || searchOperator == 'author') {
        matchingAuthors = this._searchAuthors(searchTerm)
      }

      if(!searchOperator || searchOperator == 'title') {
        matchingTitles = this._searchTitles(searchTerm)
      }

      if (matchingAuthors)
        matchingAuthors = Array.from(new Set(matchingAuthors))
        matchingBooks = matchingBooks.concat(matchingAuthors)

      if (matchingTitles)
        matchingBooks = matchingBooks.concat(matchingTitles)

      if (matchingBooks.length > 0) sortElements(matchingBooks, titleSort)

      matchingBooks.forEach((element) => {
        element.style.display = "block"
      })

      let numberFound = matchingBooks.length
      if(numberFound === 1) {
        var bookStr = "book"
      } else {
        var bookStr = "books"
      }

      document.querySelector('#nav_info').innerHTML = 'Found <strong>' + numberFound + '</strong> ' + bookStr + ' matching "<strong>' + searchTerm + '</strong>"'
      document.querySelector('#nav_info').style.display = 'block'
    }

    _searchAuthors(term) {
      let allAuthors = []
      let matchingAuthors = []

      allAuthors = Array.from(document.querySelectorAll("article ul[class='authors']"))

      allAuthors.forEach((author) => {
        if(author.textContent.toLowerCase().includes(term.toLowerCase()))
          matchingAuthors.push(author.closest("article"))
      })

      return matchingAuthors
    }

    _searchTitles(term) {
      let allTitles = []
      let matchingTitles = []

      allTitles = Array.from(document.querySelectorAll("a[itemprop='name']"))

      allTitles.forEach((title) => {
        if(title.textContent.toLowerCase().includes(term.toLowerCase()))
          matchingTitles.push(title.closest("article"))
      })

      return matchingTitles
    }

    _getSearchOperator(query) {
      let validOperators = ['title', 'author']
      let candidate = query.split(':')[0]
      if(validOperators.includes(candidate))
        return candidate
    }

    _clear() {
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
  })

  application.register("sort", class extends Stimulus.Controller {
    static targets = [ "article" ]

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
  })
})()
