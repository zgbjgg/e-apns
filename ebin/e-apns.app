{application, 'e-apns',
 [
  {description, "APNS Over Erlang"},
  {vsn, "0.2"},
  {registered, []},
  {applications, [
                  kernel,
                  stdlib
                 ]},
  {modules, ['e-apns_app', 'e-apns_sup', 'e-apns', 'e-apns_u']},
  {mod, { 'e-apns_app', []}}
 ]}.
