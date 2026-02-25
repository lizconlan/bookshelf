// there is no database
// so to add a book, we currently need to:
// 1. find the book's folder in the tree structure (at the same level as __index)
// 2. edit the book's info.js file (this is the metadata for the book)
// For example


// Create a Stimulus controller that will allow us to edit a book's metadata
application.register("edit-book", class extends Stimulus.Controller {
  static targets = ["book", "title", "author", "description", "saveButton"];

  connect() {
    this.loadBookData();
  }

  loadBookData() {
    // Load the book data from the info.js file
    // This is a placeholder for the actual implementation
    alert(book);
    const bookData = {
      filePath: "../../../../__index/books/tech/sample-book",
      fileData: File.read(filePath + "/_meta/info.js"),
      title: fileData.title,
      author: fileData.author,
      description: fileData.description
    };

    this.titleTarget.value = bookData.title;
    this.authorTarget.value = bookData.author;
    this.descriptionTarget.value = bookData.description;
  }

  saveBookData() {
    const updatedBookData = {
      title: this.titleTarget.value,
      author: this.authorTarget.value,
      description: this.descriptionTarget.value
    };

    // Save the updated book data to the info.js file
    // This is a placeholder for the actual implementation
    console.log("Saving book data:", updatedBookData);
  }
});


