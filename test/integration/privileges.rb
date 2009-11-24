require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../app/models/privilege.rb'

class PrivilegesTest < ActionController::IntegrationTest
  fixtures :users, :contracts, :enrollments

  # Replace this with your real tests.
  def test_truth
	
		privilege_names = [:create, :edit, :view, :view_students, :browse, :create_note, :edit_note, :view_note]
	
		[1,2,3].each do |i|

			@contract = Contract.find(i)
			
			puts "======================================================="
			puts @contract.name.upcase
			puts ""
			puts "User privileges on contract"
			puts "status=#{Contract::STATUS_NAMES[@contract.contract_status]}"
			puts "---------------------------------------------"
			puts "Name/Priv      Cr  Ed  Vi  Vs  Br  CN  EN  VN"
			puts "---------------------------------------------"
			
			User.find(:all).each do |u|
			
				e = @contract.enrollments.find(:first, :conditions => ["participant_id = ?", u.id])
				if e.nil?
					role_string = ": -"
				else
					role_string = ": #{Enrollment::ROLE_NAMES[e.role].slice(0,1)}"
				end
			
				privs = @contract.privileges(u)
				priv_string = u.name.ljust(10)
				priv_string << role_string.ljust(5)
				privilege_names.each do |n|
					if privs[n]
						priv_string << " X  "
					else
						priv_string << "    "
					end	
				end
				puts priv_string
			end
			puts "\n\n"

			puts "User privileges on contract child objects"
			puts "---------------------------------------------"
			puts "Name/Priv      Cr  Ed  Vi  Vs  Br  CN  EN  VN"
			puts "---------------------------------------------"
			
			User.find(:all).each do |u|
			
				e = @contract.enrollments.find(:first, :conditions => ["participant_id = ?", u.id])
				if e.nil?
					role_string = ": -"
				else
					role_string = ": #{Enrollment::ROLE_NAMES[e.role].slice(0,1)}"
				end
			
				privs = TinyPrivileges.contract_child_object_privileges(u, @contract)
				priv_string = u.name.ljust(10)
				priv_string << role_string.ljust(5)
				privilege_names.each do |n|
					if privs[n]
						priv_string << " X  "
					else
						priv_string << "    "
					end	
				end
				puts priv_string
			end
			puts "\n\n"

			puts "Privileges for contract 1 enrollments, turnins, absences"
			@contract.enrollments.each do |e|
				puts "\n#{e.participant.name}: #{Enrollment::ROLE_NAMES[e.role]}"
				puts "---------------------------------------------"
				puts "Name           Cr  Ed  Vi  Vs  Br  CN  EN  VN"
				puts "---------------------------------------------"
				User.find(:all).each do |u|
					privs = e.privileges(u)
					priv_string = u.name.ljust(15)
					privilege_names.each do |n|
						if privs[n]
							priv_string << " X  "
						else
							priv_string << "    "
						end	
					end
					puts priv_string
				end
				puts "\n\n"
			end

		
		end
		
    assert true
  end
end

