  application.register("notbook", class extends Stimulus.Controller {
    close_books() {
      document.querySelectorAll('.about').forEach((element, idx) => {
        element.style.display = "none"
      })
      document.querySelector('#fade').style.display = "none"
    }
  })
