# Changelog

## Unreleased

### Added

- `MainMenu#labels(*parents)` lists the item labels at a menu level.
- Version 2.0.0.alpha: page objects for vanilla ActiveAdmin 4 only. The gem now depends on `activeadmin` (>= 4.0.0.beta1, < 5.0.0.a). Vanilla ActiveAdmin 3 moves to the 1.x line.
- SitePrism page and sections for vanilla ActiveAdmin 4: layout, breadcrumbs, action items, flashes, main menu, index table, attributes table, panel, filters (string, numeric, select, boolean, date range), scopes, pagination, batch actions and formtastic forms.
- `ActiveAdminPageObjects.register_selectors(**map)` takes only the selector map. It can also replace a key ActiveAdmin 4 removed, such as `tabs`.
- `ActiveAdminPageObjects::Layout.add_section` and `Layout.add_element` add a section or an element to every page that includes `Layout`, including page classes defined earlier.
- `ActiveAdminPageObjects::SelectControl` drives a native `<select>` for `SelectFilter`, `Form` and `Form::Input`. A gem with a JavaScript select widget prepends a module into it.
- `ActiveAdminPageObjects.check_version!` for theme and plugin page objects. Features ActiveAdmin 4 removed raise `RemovedInActiveAdmin4`.
