User.seed do |s|
  s.id = 1
  s.email = "admin@tinysis.org"
  s.first_name = "Eric"
  s.last_name = "Artzt"
  s.login = "admin"
  s.login_status = User::LOGIN_ALLOWED
  s.status = User::STATUS_ACTIVE
  s.privilege = User::PRIVILEGE_ADMIN
  s.password = "tinyterror"
end