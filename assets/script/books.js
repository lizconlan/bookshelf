var main = function() {
  $('.pubfilter').change(function() {
    var selectedPub = $(this).val();
    if(selectedPub) { clearSearchBox(); }
    filterPublishers(selectedPub);
  });
  $('#nav_info').hide();
  $('#title_sort').hide();
  $('#pub_sort').click(function() {sortByPublisher();});
  $('#title_sort').click(function() {sortByTitle();});
  $('#fade').click(function() {hideInfo();});
}

$(document).ready(main);

let validSearchOperators = ['title', 'author']

function revealInfo(image) {
  $('#fade').show();
  var infoPanel = $(image).parent().find('.about');
  infoPanel.show();
  if(infoPanel.find('tab_set')) {
    $('.tab_content').hide();
    $(infoPanel.find('.tab_content')[0]).show();
    $(infoPanel.find('.tab_button')[0]).addClass('selected');
  }
}

function hideInfo() {
  $('.about').hide();
  $('#fade').hide();
}

function clearSearchBox() {
  $('#search_box').val("");
}

function clearPublishers() {
  $('.pubfilter').val("");
}

function resetPublishers() {
  $('.pubfilter').val("Show All");
}

function resetState() {
  hideInfo();
  $('#pub_sort').show();
  $('#title_sort').hide();
}

function showTab(tab) {
  $('.tab_content').hide();
  $('#' + tab).show();
  $('.tab_button').removeClass('selected');
  $('#btn_' + tab).addClass('selected');
}

function filterPublishers(publisher) {
  resetState();
  if(publisher === 'Show All') {
    $('#books').children().show();
    $('#sort').show();
    $('#nav_info').hide();
  } else {
    $('#books').children().hide();
    var matchingBooks = $("article p[itemprop='publisher']:contains(" + publisher +")").closest("article");
    var numberFound = matchingBooks.length;

    $('#sort').hide();
    matchingBooks.show();
    if(numberFound === 1) {
      var bookStr = "book";
    } else {
      var bookStr = "books";
    }
    $('#nav_info').html('Found <strong>' + matchingBooks.length + '</strong> ' + bookStr + ' for <strong>' + publisher + '</strong>');
    $('#nav_info').show();
  }
}

function sortByPublisher() {
  hideInfo();
  $('article').sortElements(publisherSort());
  $('#pub_sort').hide();
  $('#title_sort').show();
}

function sortByTitle() {
  hideInfo();
  resetPublishers();
  $('article').sortElements(titleSort());

  $('#title_sort').hide();
  $('#pub_sort').show();
}

function showMoreInfo(isbn, book_id) {
  target = "https://openlibrary.org/api/books?bibkeys=ISBN:" + isbn.trim() + "&jscmd=data&format=json";
  panel = $('span.ident_' + book_id);
  var data = '';

  $.getJSON(target, function(openLibJson){
    if ($.isEmptyObject(openLibJson)) {
      // console.log('No OpenLibrary data for ISBN: ' + isbn);
    } else {
     isbn_key = Object.keys(openLibJson)[0];
     data = openLibJson[isbn_key];
    }
  }).done( function() {
    panel.append('<p itemprop="datePublished">Published: ' + data.publish_date + '</p>');
    if (data.number_of_pages != undefined) {
      panel.append('<p itemprop="numberOfPages">' + data.number_of_pages + ' pages</p>');
    }
  });
}

function searchBooks(form) {
  hideInfo();
  clearPublishers();
  $('#title_sort').hide();
  $('#pub_sort').hide();
  $('#nav_info').hide();
  $('#books').children().hide();

  let matchingAuthors = []
  let matchingTitles = []
  let matchingBooks = $("article ul[class='zero-results']");

  let raw_term = form.search_box.value;
  let search_operator = getSearchOperator(raw_term);
  let search_term = raw_term.replace(search_operator + ':', '').trim();

  if(!search_operator || search_operator == 'author') {
    matchingAuthors = searchAuthors(search_term);
  }

  if(!search_operator || search_operator == 'title') {
    matchingTitles = searchTitles(search_term);
  }

  if (matchingAuthors.length > 0) { matchingBooks = matchingBooks.add(matchingAuthors) }
  if (matchingTitles.length > 0) { matchingBooks = matchingBooks.add(matchingTitles) }

  matchingBooks.sortElements(titleSort()).show();

  let numberFound = matchingBooks.length;

  if(numberFound === 1) {
    var bookStr = "book";
  } else {
    var bookStr = "books";
  }

  $('#nav_info').html('Found <strong>' + numberFound + '</strong> ' + bookStr + ' matching "<strong>' + search_term + '</strong>"');
  $('#nav_info').show();
}

function searchAuthors(term) {
  return $("article ul[class='authors']:contains(" + term + ")").closest("article");
}

function searchTitles(term) {
  return $("article a[itemprop='name']:contains(" + term + ")").closest("article");
}

function getSearchOperator(query) {
  candidate = query.split(':')[0]
  if(jQuery.inArray(candidate, validSearchOperators) !== -1) {
    return candidate;
  } else {
    return null;
  }
}

// case insensitive modifier for jQuery :contains
// lifted from CSS Tricks
// https://css-tricks.com/snippets/jquery/make-jquery-contains-case-insensitive/
$.expr[":"].contains = $.expr.createPseudo(function(arg) {
  return function( elem ) {
    return $(elem).text().toUpperCase().indexOf(arg.toUpperCase()) >= 0;
  };
});

function titleSort() {
  return function(a, b){
    title_a = $(a).find('h2')[0].textContent.trim();
    sort_key_a = title_a.trim().replace(/^(The )|(A )/, "");

    title_b = $(b).find('h2')[0].textContent.trim();
    sort_key_b = title_b.trim().replace(/^(The )|(A )/, "");

    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase());
  }
}

function publisherSort() {
  return function(a, b){
    pub_a = $(a).find('p[itemprop="publisher"]')[0].textContent.trim();
    title_a = $(a).find('h2')[0].textContent.trim();
    sort_key_a = pub_a.trim() + "__" + title_a.trim().replace(/^(The )|(A )/, "");

    pub_b = $(b).find('p[itemprop="publisher"]')[0].textContent.trim();
    title_b = $(b).find('h2')[0].textContent.trim();
    sort_key_b = pub_b.trim() + "__" + title_b.trim().replace(/^(The )|(A )/, "");

    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase());
  }
}
