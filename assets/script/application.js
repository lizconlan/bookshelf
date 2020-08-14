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
      $(".pubfilter").val("Show All")
      $("#title_sort").hide()
      $("#search_box").val("")
      $("#fade").hide()

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

  application.register("books", class extends Stimulus.Controller {
    reveal_info() {
      $("#fade").show()
      let infoPanel = $(this.element).find(".about")
      infoPanel.show()
      if(infoPanel.find("tab_set")) {
        $(".tab_content").hide()
        $(infoPanel.find(".tab_content")[0]).show()
        $(infoPanel.find(".tab_button")[0]).addClass("selected")
      }
    }
  })

  application.register("editions", class extends Stimulus.Controller {
    show_tab() {
      let tab_button = this.element
      let tab_id = this.element.id.replace("btn_", "")
      $(".tab_content").hide()
      $("#" + tab_id).show()
      $(".tab_button").removeClass("selected")
      $(tab_button).addClass("selected")
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

  application.register("notbooks", class extends Stimulus.Controller {
    close_books() {
      $('.about').hide();
      $('#fade').hide();
    }
  })

  application.register("search", class extends Stimulus.Controller {
    search_books() {
      this._clear()

      let matchingAuthors = []
      let matchingTitles = []
      let matchingBooks = $("article ul[class='zero-results']")

      let rawTerm = $("#search_box").val()
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
    publisher_sort() {
      $('.about').hide()
      $('#fade').hide()
      $('article').sortElements(publisherSort)
      $('#pub_sort').hide()
      $('#title_sort').show()
    }

    title_sort() {
      $('.about').hide()
      $('#fade').hide()
      $('article').sortElements(titleSort)
      $('#title_sort').hide()
      $('#pub_sort').show()
    }
  })
})()
