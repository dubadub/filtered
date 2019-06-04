class <%= class_name %>Filter < ApplicationFilter

<% for field in fields -%>
  field :<%= field %>
<% end -%>

end

