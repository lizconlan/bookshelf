  function sortElements(items, sorter) {
    const targetElement = items[0].parentElement

    Array.from(targetElement.children).forEach(node=>targetElement.removeChild(node))
    items.sort(sorter).forEach(node=>targetElement.appendChild(node))
  }

  function titleSort(a, b) {
    let title_a = Array.from(a.querySelectorAll("h2"))[0].textContent.trim()
    let sort_key_a = title_a.trim().replace(/^(The )|(A )/, "")

    let title_b = Array.from(b.querySelectorAll("h2"))[0].textContent.trim()
    let sort_key_b = title_b.trim().replace(/^(The )|(A )/, "")

    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase())
  }

  function publisherSort(a, b){
    let pub_a = Array.from(a.querySelectorAll("p[itemprop='publisher']"))[0].textContent.trim()
    let title_a = Array.from(a.querySelectorAll("h2"))[0].textContent.trim()
    let sort_key_a = pub_a.trim() + "__" + title_a.trim().replace(/^(The )|(A )/, "")

    let pub_b = Array.from(b.querySelectorAll("p[itemprop='publisher']"))[0].textContent.trim()
    let title_b = Array.from(b.querySelectorAll("h2"))[0].textContent.trim()
    let sort_key_b = pub_b.trim() + "__" + title_b.trim().replace(/^(The )|(A )/, "")

    return sort_key_a.toLowerCase().localeCompare(sort_key_b.toLowerCase())
  }
