var main = function() {
  $('.pubfilter').change(function() {
    var selectedPub = $(this).val();
    filterPublishers(selectedPub);
  });
  $('#select_info').hide();
  $('#title_sort').hide();
  $('#pub_sort').click(function() {sortByPublisher();});
  $('#title_sort').click(function() {sortByTitle();});
}

$(document).ready(main);

function revealInfo(image) {
  $(image).parent().find('.about').show();
  $(image).hide();
}

function hideInfo(block) {
  $(block).parent().find('img').show();
  $(block).hide();
}

function filterPublishers(publisher) {
  if(publisher === 'Show All') {
    $('#books').children().show();
    $('#sort').show();
    $('#select_info').hide();
  } else {
    $('#books').children().hide();
    var matchingBooks = $("article p:contains(Publisher: " + publisher + ")").parent().parent();
    var numberFound = matchingBooks.length;
    
    $('#sort').hide();
    matchingBooks.show();
    if(numberFound === 1) {
      var bookStr = "book";
    } else {
      var bookStr = "books";
    }
    $('#select_info').html('Found <strong>' + matchingBooks.length + '</strong> ' + bookStr + ' for <strong>' + publisher + '</strong>');
    $('#select_info').show();
  }
}

function sortByPublisher() {
  $('article').sortElements(function(a, b){
    pub_a = $(a).find('p[itemprop="publisher"]')[0].textContent.trim();
    title_a = $(a).find('h2')[0].textContent.trim();
    sort_key_a = pub_a.trim() + "__" + title_a.trim().replace(/^(The )|(A )/, "");
    
    pub_b = $(b).find('p[itemprop="publisher"]')[0].textContent.trim();
    title_b = $(b).find('h2')[0].textContent.trim();
    sort_key_b = pub_b.trim() + "__" + title_b.trim().replace(/^(The )|(A )/, "");
    
    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase());
  });
  $('#pub_sort').hide();
  $('#title_sort').show();
}

function sortByTitle() {
  $('article').sortElements(function(a, b){
    title_a = $(a).find('h2')[0].textContent.trim();
    sort_key_a = title_a.trim().replace(/^(The )|(A )/, "");
    
    title_b = $(b).find('h2')[0].textContent.trim();
    sort_key_b = title_b.trim().replace(/^(The )|(A )/, "");
    
    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase());
  });
  $('#title_sort').hide();
  $('#pub_sort').show();
}