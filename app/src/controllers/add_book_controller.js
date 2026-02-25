// there is no database
// so we currently need to add a book to a file a _meta/info.js file
application.register("add-book", class extends Stimulus.Controller {
  static targets = ["title", "authors", "isbn"]

  connect() {
    // Optional: Add any initialization logic here
  }

  add_book() {

  }

  submit(event) {
    event.preventDefault()

    const bookData = {
      title: this.titleTarget.value,
      authors: this.authorsTarget.value.split(",").map(author => author.trim()),
      ISBN: this.isbnTarget.value
    }

    // Here you would typically make an API call to save the data
    // For now, we can log it to console
    console.log("Book data to save:", bookData)
  }
})
