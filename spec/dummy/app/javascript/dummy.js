import "tom-select"

// Order filters use Tom Select, like apps that add it on top of stock ActiveAdmin.
if (window.location.pathname.startsWith("/admin/orders")) {
  document.querySelectorAll(".filters-form select").forEach((select) => {
    new window.TomSelect(select, {
      plugins: ["dropdown_input"],
      create: select.dataset.create === "true",
      allowEmptyOption: true,
      placeholder: "Choose"
    })
  })
}
