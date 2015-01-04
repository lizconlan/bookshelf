function sort_by_publisher() {
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

function list_publishers() {
  var result = [];
  // find all the articles' publisher text
  $.each($('article').find('p[itemprop="publisher"]'), function(i, txt) {
    pub_name = txt.textContent.replace('Publisher: ', '');
    if ($.inArray(pub_name, result) == -1) {
      result.push(pub_name);
      parent_article = $('article')[i];
      alert(parent_article.id);
      //parent_article.prepend('<a name="' + pub_name + '"/>');
    }
  });
  result.sort();
  
  $('#publishers').html(result);
}

function sort_by_title() {
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