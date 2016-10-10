var main = function() {
  $('.pubfilter').change(function() {
    var selectedPub = $(this).val();
    filterPublishers(selectedPub);
  });
  $('#select_info').hide();
  $('#title_sort').hide();
  $('#pub_sort').click(function() {sortByPublisher();});
  $('#title_sort').click(function() {sortByTitle();});
  $('#fade').click(function() {hideInfo();});
}

$(document).ready(main);

function revealInfo(image) {
  hideInfo();
  $('#fade').css('height', $(window).height());
  $('#fade').show();
  var infoPanel = $(image).parent().find('.about');
  infoPanel.show();
  infoPanel.css({margin:$(document).scrollTop()+100+'px 0 0 '+($(window).width() / 2 - infoPanel.width() / 2)+'px'});
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

function showTab(tab) {
  $('.tab_content').hide();
  $('#' + tab).show();
  $('.tab_button').removeClass('selected');
  $('#btn_' + tab).addClass('selected');
}

function filterPublishers(publisher) {
  hideInfo();
  if(publisher === 'Show All') {
    $('#books').children().show();
    $('#sort').show();
    $('#select_info').hide();
  } else {
    $('#books').children().hide();
    var matchingBooks = $("article p[itemprop='publisher']:contains(" + publisher +")").parent().parent().parent().parent();
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
  hideInfo();
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
  hideInfo();
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