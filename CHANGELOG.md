# Changelog

## Unreleased

### Added

- SitePrism page and sections for stock ActiveAdmin 4: layout, breadcrumbs, action items, flashes, main menu, index table, attributes table, panel, filters (string, numeric, select, boolean, date range), scopes, pagination, batch actions and formtastic forms.
- Select filters and form selects drive Tom Select when it is present.
- Markup detection (`ActiveAdminPageObjects.markup`) with one selector map per markup. ActiveAdmin 3 raises `UnsupportedMarkup`; features ActiveAdmin 4 removed raise `RemovedInActiveAdmin4`.
- `ActiveAdminPageObjects.check_version!` for plugin page objects.
