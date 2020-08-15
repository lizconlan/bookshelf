(() => {
  const application = Stimulus.Application.start()

  let titleSort = function(a, b) {
    let title_a = $(a).find("h2")[0].textContent.trim()
    let sort_key_a = title_a.trim().replace(/^(The )|(A )/, "")

    let title_b = $(b).find("h2")[0].textContent.trim()
    let sort_key_b = title_b.trim().replace(/^(The )|(A )/, "")

    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase())
  }

  let publisherSort = function(a, b){
    let pub_a = $(a).find("p[itemprop='publisher']")[0].textContent.trim()
    let title_a = $(a).find("h2")[0].textContent.trim()
    let sort_key_a = pub_a.trim() + "__" + title_a.trim().replace(/^(The )|(A )/, "")

    let pub_b = $(b).find("p[itemprop='publisher']")[0].textContent.trim()
    let title_b = $(b).find("h2")[0].textContent.trim()
    let sort_key_b = pub_b.trim() + "__" + title_b.trim().replace(/^(The )|(A )/, "")

    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase())
  }

  application.register("start", class extends Stimulus.Controller {
    initialize() {
      $("h1").css("color", "#fff")
      $("header").height(110)
      $("#nav_info").show()
      $("#filters").show()
      $(".pubfilter").val("Show All")
      $("#pub_sort").show()
      $("#search").show()
      $("#search_box").val("")
      $("#fade").hide()
      $("img[itemprop='image']").hover(function() {
        $(this).css("cursor","pointer")
      })

      // case insensitive modifier for jQuery :contains
      // lifted from CSS Tricks
      // https://css-tricks.com/snippets/jquery/make-jquery-contains-case-insensitive/
      $.expr[":"].contains = $.expr.createPseudo(function(arg) {
        return function(elem) {
          return $(elem).text().toUpperCase().indexOf(arg.toUpperCase()) >= 0
        }
      })
    }
  })

  application.register("book", class extends Stimulus.Controller {
    static get targets() {
      return [ "panel", "tabset", "button", "content" ]
    }

    reveal_info() {
      $("#fade").show()
      $(this.panelTarget).show()
      if(this.tabsetTarget) {
        this.contentTargets.forEach((element, idx) => {
          $(element).hide()
        })
        $(this.contentTarget).show()
        this.buttonTarget.classList.add("selected")
      }
    }

    show_tab(evt) {
      let idx = evt.target.dataset.idx

      // unselect all buttons
      this.buttonTargets.forEach((element, idx) => {
        element.classList.remove("selected")
      })
      this.buttonTargets[idx].classList.add("selected")

      // hide open panels
      this.contentTargets.forEach((element, idx) => {
        $(element).hide()
      })
      $(this.contentTargets[idx]).show()
    }
  })

  application.register("filter", class extends Stimulus.Controller {
    filter() {
      let selectedPub = $(".pubfilter").val()
      if(selectedPub) { $("#search_box").val("") }
      this._filterPublishers(selectedPub)
      $("#title_sort").hide()
      $("#pub_sort").show()
    }

    _filterPublishers(publisher) {
      $(".about").hide()
      $("#fade").hide()
      $("#pub_sort").show()
      $("#title_sort").hide()
      if(publisher === "Show All") {
        $("#books").children().show()
        $("#sort").show()
        $("#nav_info").hide()
      } else {
        $("#books").children().hide()
        var matchingBooks = $("article p[itemprop='publisher']:contains(" + publisher +")").closest("article")
        var numberFound = matchingBooks.length

        $("#sort").hide()
        matchingBooks.show()
        if(numberFound === 1) {
          var bookStr = "book"
        } else {
          var bookStr = "books"
        }
        $("#nav_info").html("Found <strong>" + matchingBooks.length + "</strong> " + bookStr + " for <strong>" + publisher + "</strong>")
        $("#nav_info").show()
      }
    }
  })

  application.register("notbook", class extends Stimulus.Controller {
    close_books() {
      $('.about').hide();
      $('#fade').hide();
    }
  })

  application.register("search", class extends Stimulus.Controller {
    static get targets() {
      return [ "term" ]
    }

    search_books() {
      this._clear()

      let matchingAuthors = []
      let matchingTitles = []
      let matchingBooks = $("article ul[class='zero-results']")

      let rawTerm = this.termTarget.value
      let searchOperator = this._getSearchOperator(rawTerm);
      let searchTerm = rawTerm.replace(searchOperator + ':', '').trim()

      if(!searchOperator || searchOperator == 'author')
        matchingAuthors = this._searchAuthors(searchTerm)

      if(!searchOperator || searchOperator == 'title')
        matchingTitles = this._searchTitles(searchTerm)

      if (matchingAuthors.length > 0)
        matchingBooks = matchingBooks.add(matchingAuthors)

      if (matchingTitles.length > 0)
        matchingBooks = matchingBooks.add(matchingTitles)

      matchingBooks.sortElements(titleSort).show()

      let numberFound = matchingBooks.length
      if(numberFound === 1) {
        var bookStr = "book"
      } else {
        var bookStr = "books"
      }

      $('#nav_info').html('Found <strong>' + numberFound + '</strong> ' + bookStr + ' matching "<strong>' + searchTerm + '</strong>"')
      $('#nav_info').show()
    }

    _searchAuthors(term) {
      return $("article ul[class='authors']:contains(" + term + ")").closest("article")
    }

    _searchTitles(term) {
      return $("article a[itemprop='name']:contains(" + term + ")").closest("article")
    }

    _getSearchOperator(query) {
      let validOperators = ['title', 'author']
      let candidate = query.split(':')[0]
      if(jQuery.inArray(candidate, validOperators) !== -1) {
        return candidate
      } else {
        return null
      }
    }

    _clear() {
      $('.about').hide()
      $('#fade').hide()
      $('.pubfilter').val("")
      $('#title_sort').hide()
      $('#pub_sort').hide()
      $('#nav_info').hide()
      $('#books').children().hide()
    }
  })

  application.register("sort", class extends Stimulus.Controller {
    static get targets() {
      return [ "article" ]
    }

    publisher_sort() {
      $('.about').hide()
      $('#fade').hide()
      $(this.articleTargets).sortElements(publisherSort)
      $('#pub_sort').hide()
      $('#title_sort').show()
    }

    title_sort() {
      $('.about').hide()
      $('#fade').hide()
      $(this.articleTargets).sortElements(titleSort)
      $('#title_sort').hide()
      $('#pub_sort').show()
    }
  })
})()
