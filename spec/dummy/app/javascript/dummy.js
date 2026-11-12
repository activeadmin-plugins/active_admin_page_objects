import "tom-select"

// Order filters use Tom Select, like apps that add it on top of stock ActiveAdmin.
if (window.location.pathname.startsWith("/admin/orders")) {
  document.querySelectorAll(".filters-form select").forEach((select) => {
    new window.TomSelect(select, {
      // Value selects get remove_button, which adds a "×" to the item text.
      plugins: select.dataset.searchMethods === undefined ? ["dropdown_input", "remove_button"] : ["dropdown_input"],
      create: select.dataset.create === "true",
      allowEmptyOption: true,
      placeholder: "Choose"
    })
  })
}
