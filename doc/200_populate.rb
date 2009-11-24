class Populate < ActiveRecord::Migration
  
  include Breakpoint
  
	def self.up
	
		do_enrollments = false
		
		# POPULATE THOSE CONSARNED EALRs
		
		require RAILS_ROOT + '/db/migrate/data/ealrs.rb'
		ealrs = make_ealrs
		
		today = Time.now
		ealrs.each do |c|
			puts c[:category]
			c[:ealrs].each do |e|
				Ealr.create(:category => c[:category], :seq => e[:seq], :ealr => e[:description], :version => today)
			
			end		
		end
	
		puts "importing staff"
		staff = File.open(RAILS_ROOT + "/db/migrate/data/staff.csv")
		line = 1
		staff.each do |s|
		  # Artzt,Eric,webmonkey,artzte@baddabigboom.com,User::PRIVILEGE_ADMIN
			s =~ /([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$/
			puts "staff.csv line #{line}" if $1.nil?
			last_name = $1
			first_name = $2
			title = $3
			email = $4
			privilege = eval($5)
			login = User.unique_login(last_name, first_name)
			user = User.new :last_name => last_name,
				:first_name => first_name, 
				:email => email
			user.privilege = privilege
			user.login_status = User::LOGIN_ALLOWED
			user.user_status = User::STATUS_ACTIVE
			user.login = login
			pass = User.random_password
			user.password = pass
			user.save!
			
			puts "#{last_name},#{first_name},#{login},#{pass}"
			
			line += 1
		end
		staff.close
		
		puts "importing students"
		line = 1
		raise(ArgumentError, "failed to open students.csv") unless students = File.open(RAILS_ROOT + "/db/migrate/data/students.csv")
		students.each do |s|
			next if s.empty?
			# Barber,Alexandria,5851910,F,WH,10/23/91,15,10,6
			unless s =~ /^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^\s]+)$/
				raise(ArgumentError, "CSV parse failed on line #{line} of students.csv:\n#{s}")
			end
			last_name = $1
			first_name = $2
			district_id = $3
			gender = $4
			ethicity = $5
			birthdate = $6
			age = $7
			district_grade = $8.to_i
			homeroom = $9

			unless birthdate =~ /^(\d+)\/(\d+)\/(\d+)$/
				raise(ArgumentError, "Birthdate parse of #{birthdate} failed on line #{line} of students.csv:\n#{s}")
			end 
			month = $1.to_i
			day = $2.to_i
			year = $3.to_i+1900
			birthdate = Time.mktime(year, month, day)
			login = User.unique_login(last_name, first_name)
			user = User.new :last_name => last_name, 
			            :first_name => first_name, 
			            :district_id => district_id, 
			            :district_grade => district_grade,
			            :birthdate => birthdate
			user.login = login
			user.login_status = User::LOGIN_NONE
			user.privilege = User::PRIVILEGE_STUDENT
			user.user_status = User::STATUS_ACTIVE
			pass = User.random_password
			user.password = pass
			
			puts "Error saving user #{last_name}, #{first_name}; line #{line}; errors:\n#{user.errors.inspect}" if !user.save
			line += 1
		end
		students.close

		puts "making unassigned"
		User.unassigned
		
		puts "logging users"
		log = File.new("users.csv", "w")
		log << "\"User Name\",\"ID\",\"Privilege\"\n" 
		User.find(:all, :order => "privilege, last_name, first_name").each do |u|
			log << "\"#{u.last_name}\",\"#{u.first_name}\",\"#{u.id}\",\"#{User::PRIVILEGE_NAMES[u.privilege]}\"\n" 
		end
		log.close
		
		# POPULATE LEARNING PLAN GOALS

		LearningPlanGoal.create :description => "Weekly contact will be through coor group meetings and one-on-one meetings with your coordinator, as applicable.", :active => true, :required => true, :position => 1
		LearningPlanGoal.create :description => "Your coordinator will meet with you monthly to determine if you are making progress on your learning plan.", :active => true, :required => true, :position => 2
		LearningPlanGoal.create :description => "If you are not making progress on your learning plan for two consecutive months, you and your coordinator will develop a revised written plan that will include the tracking of actual hours engaged in learning activities.", :active => true, :required => true, :position => 3
		

		# POPULATE TERMS
		puts "making terms"
		Term.create :name =>"COOR/2006", 
			:schoolyear=>2006,
      :active => true,
			:term => Term::TERM_FULLYEAR
		Term.create :name =>"Fall 2006", 
			:schoolyear=>2006,
      :active => true,
			:term => Term::TERM_FALL
		Term.create :name =>"Spring 2007", 
			:schoolyear=>2006,
      :active => true,
			:term => Term::TERM_SPRING
		Term.create :name =>"Unassigned", 
			:schoolyear=>0,
      :active => true,
			:term => Term::TERM_FULLYEAR
			
		Setting.current_year = 2006
		
		Setting.periods = [  
		  ClassPeriod.new("8:45", "10:15" ),
    	ClassPeriod.new("9:15", "10:15" ),
    	ClassPeriod.new("10:15", "11:45" ),
    	ClassPeriod.new("12:15", "13:00" ),
    	ClassPeriod.new("13:00", "14:30" ),
    	ClassPeriod.new("14:30", "16:00" )
    ]

		# POPULATE CREDITS
		puts "making credits"
		credits_hash = [
			{ :name => "TBD",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_NONE },
			{ :name => "IEP",
					:course_id => 0,
					:req => 3.0,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Language Arts",
					:course_id => 0,
					:req => 3.0,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Mathematics",
					:course_id => 0,
					:req => 2.0,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Science",
					:course_id => 0,
					:req => 2.0,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Social Studies",
					:course_id => 0,
					:req => 3.0,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Physical Education",
					:course_id => 0,
					:req => 2.0,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Occ. Education",
					:course_id => 0,
					:req => 1.5,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Fine Arts",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Health",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "World Languages",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_GENERAL },
			{ :name => "Electives",
					:course_id => 0,
					:req => 5.0,
					:course_type => Credit::TYPE_COURSE },
			{ :name => "Language Arts 9a",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE },
			{ :name => "Language Arts 10a",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Language Arts 11a",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Language Arts 12a",
					:course_id => 14,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Language Arts 12h",
					:course_id => 24,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "World History I",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "World History II",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "World History III",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "U.S. History 11a",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "U.S. History 11b",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "American Government and Economics 12",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE },
			{ :name => "Washington State History and Government",
					:course_id => 0,
					:req => 0.5,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Music Survey",
					:course_id => 6590,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Speech",
					:course_id => 203,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Creative Writing",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE },
			{ :name => "Poetry",
					:course_id => 790,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Math 3a",
					:course_id => 790,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Math 3b",
					:course_id => 790,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Biological Science",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Life Science",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Chemistry",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Marine Biology",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "Physical Science",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "French 1a",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "French 1b",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "French 2a",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  },
			{ :name => "French 2b",
					:course_id => 0,
					:req => 0.0,
					:course_type => Credit::TYPE_COURSE  }
	 	]
		
		Category.create(:category_name => "COOR", :sequence => 1)
		Category.create(:category_name => "Seminar", :sequence => 20)
		Category.create(:category_name => "Committee", :sequence => 30)
		credits_hash.each do |c|
			credit = Credit.new(:course_name => c[:name], 
													:course_id => c[:course_id],
													:course_type => c[:course_type],
													:required_hours => c[:req])
			credit.save
			
			# also create a category if it's a general type
			if c[:course_type] == Credit::TYPE_GENERAL
			
				category = Category.new(:category_name => c[:name], :sequence => 100)
				category.save
			
			end
		end
		
		# POPULATE CONTRACTS AND ENROLLMENTS
		puts "making contracts"
		contracts = [	
		{
			:name => "Women's Seminar",
			:facilitator => 'Eyva',
			:learning_objectives => "This seminar will be designed and co-facilitated by the interested women and will thus take shape around their interests. This seminar is designed to be a small, supportive seminar to discuss advanced topics in women's history, queer history, women and nature, women in science, feminization of science, women's health and more. If the students are willing, I would like this seminar to meet in some mature and comfortable environment that will serve as a ritual that models the benefits of creating intellectual women's space.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Seminar").id
		},
		{
			:name => "Hip-Hop",
			:facilitator => 'Nehamiah',
			:learning_objectives => "In this class we will analyze the dopest phenomenon on planet earth Hip-Hop. We will be studying hip-hop's past, evolution and the four elements. We will have historic North West mcs, djs, b boys, and aerosol artists coming through to the spot. Be ready to step out of your comfort zone because we will be writing raps, b boyin, and having in depth conversations.  Do not take this class if you are frontin' and just want credit. Although I am a student I'll, give you a fatty goose egg ZERO.",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("Fine Arts").id }] ,
			:category => Category.find_by_category_name("Fine Arts").id
		},
		{
			:name => "Middle Eastern Dance",
			:facilitator => 'Varvara',
			:learning_objectives => "If you decide to take this class you will learn a new way to be comfortable with your body and become more self-confident.  We'll delve not only into physical exercise but the rich culture and history of the Middle East so that you can be fully informed about the dance you will be learning. I have been belly dancing for some time and now am using the tools I have learned to dance professionally.  I may still be a student as well, but I want to share my experiences with the rest of you.  Guys and girls are both welcome of course, so don't let that stop you.  Come earn some P.E. credit in a fun and beautiful way!",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Fine Arts").id }],
			:category => Category.find_by_category_name("Fine Arts").id
		},
		{
			:name => "Graphic Novels Literature",
			:facilitator => 'Barbara',
			:learning_objectives => "This class is dedicated to reading both fiction and nonfiction literature in the Graphic Novel form.  In addition to discussing the readings, we will look at answering the questions: What are the characteristics of graphic novels?  How do they differ from traditional texts?  How does visual literacy affect our understanding of stories?  We will also try our hand and writing and creating graphics novels of our own.  Some of the books that we will read include Love & Rockets, Maus (I and II), Promethea, Dead West, Persepolis, Hicksville, Kafka's Metamorphosis, and Crime and Punishment by Dostoyevsky, in addition to student suggested readings.",
			:credits => [{:hours=>0.25, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Language Arts").id 
		},
		{
			:name => "Opera Studies",
			:facilitator => 'Barbara',
			:learning_objectives => "Opera is an art form that combines music, drama, and spectacular sets to thrill and envelope its viewers.  Opera in the 18th and 19th centuries was \"popular music\" (with stars and groupies, triumphs and scandals).  This class is a relaxed and friendly introduction to an art form some consider tedious, snobbish and extravagant; and others consider high passion and the best thing happening in theatre. We will listen to, watch, read about and discuss stories about mythology; the beginning or end of the world; fairy tales; love won, love lost, love transformed, death by love; finding or losing religious faith; political commentary; talking foxes, mermaids who give up their tails, or singing corpses. There are also additional lectures in the evenings and on Saturdays, which are presented by Seattle Opera staff and are optional. Opera Studies students get preference for dress rehearsal tickets at Seattle Opera.  Students are welcome to take this class multiple times.",
			:credits => [{:hours=>1, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Language Arts").id 
		},
		{
			:name => "Choir",
			:facilitator => 'Barbara',
			:learning_objectives => "YOU SHOULD TAKE THIS CLASS!!! This is why, cuz' this class is being taught by Brian a former nova student and, It will not be a typical chorus so no church music here. Songs will include Bohemian Rhapsody, Hotel California and other harmony oriented songs to be decided by the class. In this class we'll learn the basics of singing, proper breathing techniques and useful warm-ups and exercises for the voice. This class will be for fine arts credit and will require at least one writing assignment possibly more. A minimum attendance will be mandatory and if a student does not attend the required amount of classes they will be dropped from the class and will NOT receive credit in this course, so that means mo flakes. If possible please bring a song to sing w/o music to demonstrate pitch and range. It is not a try out so don't worry no one will be turned away because of a lack of singing ability, because if you can talk you can sing or at least learn to sing.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Fine Arts").id }],
			:category => Category.find_by_category_name("Fine Arts").id 
		},
		{
			:name => "All City Arts Animation Sector (advanced, evening class at the Frye art museum)",
			:facilitator => 'Stefan',
			:learning_objectives => "The setting for this class will be a workshop environment that provides an inspiring space, assistance and materials for advanced animators who are working on their own animation visions. A major phase of the class will involve building stop motion animation. The goal of those projects is to delve into the hidden personas of ordinary objects and expose them. We will study the works of stop motion masters, absorb the upcoming shows at the Frye, and the most awesome part is our works will be exhibited in the Frye art museum as part of a show on humorous sculpture.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Fine Arts").id
		},
		{
			:name => "Collaborative Animation A (beginning)",
			:facilitator => 'Stefan',
			:learning_objectives => "This is a class that shows how many fantastic techniques have been invented by animators. We'll embark upon a new animation technique every week. We work in a group, with equal parts creativity added by each, and we usually end up making 4 or 5 short collaborative films together. Techniques explored include Pixilation, (animation of the human body) Flipbooks, Stop-Motion Animation, and Claymation. The big goal is to have everyone see the material world as potential art supplies, and to bring them in and try working them into animation pieces. As animation materials we've used Tinfoil, broken glass, Ice, Snow, everything. The most important thing to bring to this class is patience. No drawing skills are necessary. The best thing to bring is a natural curiosity as to what animation is. The finished works made in this class are burned to DVD and shown in an actual theater at the end of the second semester.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Fine Arts").id
		},
		{
			:name => "Experimental Animation (advanced)",
			:facilitator => 'Stefan',
			:learning_objectives => "Experimental Animation is a workshop designed to make the materials and resources available for the independent animator. 1st semester focuses on developing soundtracks before animation, so that lip-synch is possible. We will be able to have a professional style punched-paper animation area, one or two long-term 3-D animation setups; Flash will be available as well. Materials: Most supplies are supplied; some self-budget (probably under $20) may be needed. The finished works made in this class are burned to DVD and shown in an actual theater at the end of the 2nd semester.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Fine Arts").id
		},
		{
			:name => "Collaborative Animation B (beginning)",
			:facilitator => 'Stefan',
			:learning_objectives => "This is a class that shows how many fantastic techniques have been invented by animators. We'll embark upon a new animation technique every week. We work in a group, with equal parts creativity added by each, and we usually end up making 4 or 5 short collaborative films together. Techniques explored include Pixilation, (animation of the human body) Flipbooks, Stop-Motion Animation, and Claymation. The big goal is to have everyone see the material world as potential art supplies, and to bring them in and try working them into animation pieces. As animation materials we've used Tinfoil, broken glass, Ice, Snow, everything. The most important thing to bring to this class is patience. No drawing skills are necessary. The best thing to bring is a natural curiosity as to what animation is. The finished works made in this class are burned to DVD and shown in an actual theater at the end of the second semester.",
			:credits => [{:hours=>0.25, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Fine Arts").id
		},
		{
			:name => "Transition Planning",
			:facilitator => 'Sheilah',
			:learning_objectives => "What do you want to do when you get out of high school?  What do you need to do to prepare?  Are your goals realistic?  Do you know what kinds of assistance you may be eligible for and how to get it?  Can you advocate for yourself?  This class will help you answer all of these questions and explore other aspects of future planning.  We'll talk about job applications and interviews, budgeting/bill paying, living arrangements, choosing a college, transportation options – whatever you need to know to help you make a successful transition to Real Life.  Guest speakers and field trips may be included.  Your course of study and assignments will be determined by what you identify as your goals and what you need to learn, and do, to achieve them.  Put the ‘fun' in functional & give yourself a head start on your future.",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("IEP").id }],
			:category => Category.find_by_category_name("Seminar").id
		},
		{
			:name => "Literacy = Power",
			:facilitator => 'Laura',
			:learning_objectives => "Would you rather clean the bathroom than read a book? Do you get lost after the first few pages of a reading assignment? Do you draw a blank after a couple of lines of writing? Do you skip writing assignments altogether? Participation in this class will increase your skills in reading and writing using assignments based on your personal interests and goals. Open to students with and without IEPs.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("IEP").id }],
			:category => Category.find_by_category_name("IEP").id
		},
		{
			:name => "Open Lab",
			:facilitator => 'Joleen',
			:learning_objectives => "Do you need a quiet place to work? Need some feedback on an assignment? Want some help on a project? Stop in the learning center during open lab and get support with all things academic.",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Seminar").id
		},
		{
			:name => "Writing Well",
			:facilitator => 'Laura',
			:learning_objectives => "Whether it's a love note, a college entrance essay, or a cover letter for your dream job, clear written communication is vital to getting what you want in life. This class will cover the basics of practical techniques to make all of your writing clear and effective. Open to students with and without IEPs.",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Math Enhancement",
			:facilitator => 'Joleen',
			:learning_objectives => "This course will have an intense focus on and will review math foundational skills, including multiplication, division, fractions, decimals, ratio, conversions, statistics, and story problems.  There will be an emphasis on being able to explain the math processes you use to solve mathematical problems in both oral and written formats.  Credit will vary depending on the needs of the student and amount of time needed to meet the competencies.  This course is offered in the following time increments: 45 min one time per week 90 min one time per week plus Independent Contract 45 min Independent Contract/Inclusion class 90 min two times per week",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Learning Math Fundamentals through the Looking glass of Algebra",
			:facilitator => 'Joleen',
			:learning_objectives => "Learn your foundational skills including multiplication, division, fractions, and decimals using algebraic expressions and equations.  Basic algebraic formulas and processes will be taught.  There will be an emphasis on being able to explain the math processes you used to solve mathematical problems in both oral and written formats.  This course will involve group work as well as individual work. Note: This is a required course for IEP students with math SDI",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Skills for Success Seminar",
			:facilitator => 'Joleen',
			:learning_objectives => "Learn the 7-Highly Effective Habits; how to manage those long-term assignments; keep a planner and recordkeeping systems; choose an organizational system that works for you; set and attain learning, personal, and community goals; ways to organize your time and different methods of studying; learn and understand your own learning Style, and learn how to maximize your accommodations here at Nova and at the college level.  There will also be time for independent study time with teachers available for assistance.  This course is offered in the following time increments: 45 min one time per week  45 min twice per week45 min one time per week Independent Contract 90 min two times per week",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Seminar").id
		},
		{
			:name => "Tutoring/Independent Contract",
			:facilitator => 'Joleen',
			:learning_objectives => "This is an option for IEP students who have been recommended to receive their SDI (i.e. Math, LA, Social Skills, etc.) in and a tutorial format.  The Independent Contract is required and .25 Unspecified elective credit will be given.  Student will meet with Joleen or Laurie to set up this course. All students in this course are required to meet with their facilitator twice a week during a 1-1tutoring Session (see schedule). Note: This meets the following requirement for Skills for Success",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Seminar").id
		},
		{
			:name => "Community Projects",
			:facilitator => 'Joleen',
			:learning_objectives => "Want to get those service learning hours documented?  Want to try your hand at developing your own small business?  What about fundraising for an outdoor experience (camping trip)?  Or how about designing and implementing service learning projects, like making Piñatas, cooking, quilt making, or other projects that we can turn into a project that will be for the community?  This is your hands-on course with lots of group work.  We need you and your ideas.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Electives").id }],
			:category => Category.find_by_category_name("Seminar").id
		},
		{
			:name => "Playwriting",
			:facilitator => 'Varvara',
			:learning_objectives => "This semester ACTheatre (American Contemporary Theatre) in down town Seattle is partnering once again with NOVA to create your own scripts.  In class you will learn the basics of dialogue writing, characterization, shaping your story into a dramatic arc and setting.  You will be the one who will steer the course of your script, but you will receive feed back from a professional playwright, as well. You will act as a group of fledging artists supporting each other in the process, taking time to write, experiment, listen, share and provide opportunities for further tuning your writing skills.  There will be opportunities for in-class readings,  possibilities for publishing, or actually putting your text on its feet with actors to begin to realize the story.  You will also have the opportunity to work with Todd Moore, a professional playwright, to gain professional feedback, as well as to prepare you to submit your script to ACT Young Playwrights Festival for Spring 2007. The finished play submission is due December 12, 2006. You will also be expected to cooperate on creating a collaborative piece of your work for the evening of Exhibition Night at the end of January 2007.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Punk your Junk",
			:facilitator => 'Terrance',
			:learning_objectives => "A seminar style class dedicated to exploring and discussing literatures, music, and art that construct the attitudes, beliefs, and habits of different punk scenes.  In addition to studying punk ethos, students will create multiple writing and visual art projects that represent their individual ideas that address the question, \"What is punk?\"",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Passion of the Corpse",
			:facilitator => 'Eyva',
			:learning_objectives => "We will be watching many zombie movies and even trying to create our own zombie short film and this will be an intensive writing class. Several papers, a response journal, a large project and full class participations will be required for credit. For a focused and critical analysis of this genre we are focusing on the Romero cannon of classics and the films leading to and evolving from this cannon. We are not including all undead movies. You can teach your own class in the future if you want to explore the diverse and full genre of vampire films but that will not be part of this class. We will also look at the social impact of this genre, including zombie survival books, websites and games, zombie movie's contributions to make-up and special effects and the always present social commentary in zombie films.  A permission slip will be required for all students because Rated R movies will be an important part of this curriculum. The short film will most likely be made at an overnight so your willingness to stay at Nova all night is also necessary for full credit!",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Reading and Writing as Daily Practice",
			:facilitator => 'Debbie',
			:learning_objectives => "Let's read. Let's write. Let's create. Let's discuss. Read books and poetry and short stories and essays. Write in different genres: journal entries, poetry, short story, and essay.  Create book projects.  Watch movies and talk about them.  Here's the lowdown: this is the one language arts class at Nova that isn't specific – we'll cover anything and everything.  Bring your energy, your thoughts, and your writing implement! For credit you will read four books and complete related assignments, write 30 pages of journal, three poems, one essay with drafts, and one short story with drafts. Theme for this semester: learning styles; so come prepared for introspection. Note: Students cannot take this more than two semesters. Maximum size: 40, so sign up ASAP",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Senior Literature",
			:facilitator => 'Barbara',
			:learning_objectives => "In this class we will read several classic pieces of literature paired with contemporary works. The Iliad, a Greek war epic will be paired with Tim O'Brien's 20th c. American novel about Vietnam, The Things They Carried, and /or Johnny Got His Gun by Dalton Trumbo; Sophocles' play, Antigone, with the German film, The Nasty Girl about a teenager who asks questions about Nazi collaborators; Oedipus with the musical Gospel at Colonnus; The Bacchae with the non-fiction reportage of Jon Krakauer, Under the Banner of Heaven; the epic Beowulf with John Gardner's novel, Grendel, where the monster gets to talk back, and more. This class is seminar style and participants need to attend regularly and keep up with the readings in order to be able to contribute in class discussions.  The writing assignments in this class ask for synthesis of the reading and original ideas.  The class will discuss the development of literature and questions like: what's the message when a blind guy is the only character who can see clearly, is it okay to use insulting language in satire, is there any art that should be censored, is it better to die and make a point or live and face the problem.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "What's Next and How To Get There",
			:facilitator => 'Barbara',
			:learning_objectives => "This class is for seniors (and the few juniors) who plan to graduate in 2007, and want help with graduation requirements like sr. essay and sr. research paper, and creating semi-independent contracts to make up for some random amount of credit from a class where the student didn't get full credit, writing college entrance essays, formalizing a study plan for the SATs, or compiling an academic portfolio to accompany a standard college application.  Additionally, the class will encourage and support seniors who want to explore an interest/passion via a culminating/senior project or work on a presentation/oral defense of what they have learned in high school, and receive credit for that preparation.  Or, all of the above.",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Seminar").id
		},
		{
			:name => "Lit & Film Studies",
			:facilitator => 'Melissa',
			:learning_objectives => "What experiences shape us as we move into adulthood? What sticks and why? What does the intersection of various cultures and/or influences bring to our lives? How and what do we think, feel and do against sometimes powerful outside forces in which we may not \"fit in\" and/or have power? Tentative texts may include: Buried Onions, The Coldest Winter Ever, Woman Warrior, Drown, The Things They Carried, \"Real Women Have Curves\", \"Pelle the Conqueror\", The Lone Ranger & Tonto Fistfight In Heaven, Bless Me Ultima, Yellow Raft On Blue Water.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "9th Grade Seminar",
			:facilitator => 'Debbie',
			:learning_objectives => "the 9th Grade Seminar is an opportunity for incoming 9th graders to build a learning community with a focus in communicating competencies.  It is a required course for all 9th graders during their first semester.  Successful completion of this course will lay a strong foundation for success at Nova. This is a student designed course developed around a set of competencies common to each section of the course.  The competencies include: writing, reading, presentation, research, inter/intra-personal skills, and critical illiteracies. Students will create a portfolio of work and show their learning through performance assessment.  The sections will usually meet separately, but will come together for joint activities, such as library fieldtrips, speakers, and group discussions and presentations.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Essay",
			:facilitator => 'Debbie',
			:learning_objectives => "This course is designed for anyone who wishes to write more powerful, interesting, and thoughtful essays of all types—expository, narrative, persuasive, compare/contrast, analytical, and more. Before writing we will engage in activities that will enhance and inform the writing process.   We will read both classic and contemporary essays and consider issues of qualities (ideas, organization, voice, word choice, sentence fluency, and conventions).  Each week we will practice some aspect of essay writing, consider the techniques of published writing, and share our own works in progress. Note: For credit you will read write six polished essays and complete in-class writing and reading assignments.  Maximum size: 25, so sign up ASAP",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Beginning Poetry Writing",
			:facilitator => 'Barbara',
			:learning_objectives => "Poetry is an art where the sum of its words equals more than its parts.  We will explore words combined in a variety of formats and avenues including written, spoken, hurled, whispered and used as bait.  We will read and hear other poets (local, international, live, recorded, published, young, ancient); learn tools that make poetry sing, confuse, explain; look at forms from ode to slam; and most days we will write poems.  Class attendance and participation is important both so others get to hear our poems and so we learn to comment/critique both respectfully and in ways that help other poets develop.  There will be opportunities but no requirement for poets to read in outside venues.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Short Story",
			:facilitator => 'Terrance',
			:learning_objectives => "Students taking this course will study the writing form of the short story by reading and writing short stories.  Students will write everyday in class in order to gain the skills needed to finish writing two short stories for the class.  These in-class writings will consist of free writing, writing to a prompt, and writing exercises.  Students will also learn how to write an annotation about a short story of their choice, and write a bookstore review.  Students will read the work of many short story writers – from Dorothy Allison to Sherman Alexie.  In class, students will participate in close reading to identify elements of plot, character, point of view, conflict, resolution, and style in literature.  Students will share critical comments on both in-class and out-of-class reading.  Students will also learn how to share critical comments on each other's work through peer editing and work shopping their peers' stories.  Students will work on developing their voice for presentations (reading their own work) and have the option of doing a reading at the school.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Language Arts").id }],
			:category => Category.find_by_category_name("Language Arts").id
		},
		{
			:name => "Tricks to Trig and Advance on Algebra",
			:facilitator => 'Freddie',
			:learning_objectives => "Congratulations! You are doing math for the fun of it (and perhaps to get into college).  We will put the syllabus together from a map of advanced algebra, geometry, trig, statistics, and other topics of your choosing.  The class offers multiple assessment opportunities including student written quizzes, presentations, projects and artistic expression.  I ask my students to support the learning community, help run the class, work in groups and make presentations (which can also be documented for graduation e-portfolios).  Please come with some good algebra skills from your 1A,B and 2A,B equivalent classes. We will pre-assess our Algebra skills at the beginning to make sure the class is a good match for you. We will continue second semester for those who want more but please also feel free to take just one semester of this class.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Foundations of Mathematics",
			:facilitator => 'Chris',
			:learning_objectives => "If you have had trouble learning math or you simply do not think math is interesting or relevant, this is the class for you. We will stress the importance of reason and logic through mathematics and how it applies to other subject areas. We will focus on: written and oral communication skills, number sense and operations, thinking and problem solving skills, and introductions to statistics, probability, geometry, and algebra. Through projects, group work, skills practice, and tutoring, students will exit this class with the knowledge and experience needed for more advanced math classes. Attendance and participation are vitally important and are therefore mandatory.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Pre-Calculus",
			:facilitator => 'Sheri',
			:learning_objectives => "This class will put the \"fun\" into functions as we explore the various mathematical models used in biology, physics, chemistry, and the social sciences. Our primary focus will be on connections between mathematics and everyday life. With an emphasis on reasoning and problem solving, students will explore this territory through projects, group work, and presentations. This class will prepare students for various upper level mathematics classes, especially calculus.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Math and the Arts",
			:facilitator => 'Eyva',
			:learning_objectives => "This course is an project-based math class where all of the art modalities (visual arts, music, drama, movement, storytelling, poetry) will be used to get a deeper understanding of math concepts. This class is designed for students who need math credit to graduate but haven't been successful in past math courses, students who enjoy the arts but haven't found a connection to math and students who feel this type of a math class might work for them. Students will be co-creating the class so bring your ideas and interests.",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Calculus For All",
			:facilitator => 'Freddie',
			:learning_objectives => "We will demystify calculus, the mathematics of change.  The class offers multiple assessment opportunities including projects and artistic expression.  I ask my students to work in groups and to make presentations (which can also be documented for e-portfolios).  Our textbook is the very funny \"Calculus for Dummies\" as well as some good standard text when we want to see what everyone else is doing.  Please come with some Pre-calculus equivalent work but don't hesitate to try it. The fundamentals of calculus just aren't that hard! We will continue second semester for those who want more but please also feel free to take just one semester of this class.  This is a great class to prepare you for advanced math and calculus study in college and we will cover how to survive college math second semester.  If you are looking for college credit this year I recommend doing Running Start instead of this class.  This is not an AP course to prepare you for AP exams.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Geometry and Movement",
			:facilitator => 'Sheri',
			:learning_objectives => "Bring geometry off the page and into your body.  Angles, measurements, spatial relationships all become so much more real when you move through them.   We will work alternately with books, pencil and paper and with the room, movement, and your body.  Get the body to support your mind and visa versa with elements of Capoeira, mime, butoh, and other physical means of math/self-expression.  Working your mind and body together, you get a deeper understanding.  The challenge of applying the work to movement will be facilitated by the teacher, but students are integral part of process of discovering how to demonstrate geometric concepts physically.  Assessment will be a blend of straightforward tests, participation, and performance.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Algebra",
			:facilitator => 'Sheri',
			:learning_objectives => "This class will expand upon previous math experiences and focus on problem solving, linear systems, functions, and graphing. We will utilize group work, skills practice, and projects to understand these concepts and to be able to utilize them in real-world situations. Social justice issues will be at the heart of making algebra relevant. We will also touch on more advanced algebra topics such as quadratic functions, matrices, and vectors.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Mathematics").id }],
			:category => Category.find_by_category_name("Mathematics").id
		},
		{
			:name => "Basic Web Design",
			:facilitator => 'Debbie',
			:learning_objectives => "This is a class for students who have no previous experience creating web pages or sites.  The semester long goal will be for each student to create their own personalized website. While students will be learning new skills throughout the course, they will constantly be encouraged to develop their own unique identities in cyberspace. We will be using Adobe GoLive to create the website, Adobe Photoshop to manipulate images to put on the websites, and the Internet as a source of endless information and advice. Students will periodically be tested on their new knowledge. Class discussions will revolve around issues of originality, time management/diminishing returns, copyright issues, and much more.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Occ. Education").id }],
			:category => Category.find_by_category_name("Occ. Education").id
		},
		{
			:name => "Sister School Trip to East Timor",
			:facilitator => 'Joseph',
			:learning_objectives => "Are you interested in making a difference in the world and getting credit for it? If so, this is the class for you. Indonesia invaded the small Portuguese colony of East Timor in 1975 with the backing of the U.S. As a result of the occupation, roughly a third of the people were killed. Nova students and staff have been involved in helping to assist the victims of this hidden holocaust since 1993. For the last 4 and a half years Nova has had a sister school relationship with a high school in East Timor. We have sent over $20,000 to help them with much needed supplies and made great personal connections with our students from our sister school.  In 2005 10 Nova students traveled to East Timor to connect with students from our sister school and help assess what they need to rebuild their school, which was destroyed in the violence promoted by the US and Indonesia. East Timor is the world's newest country (since 2002) and is still recovering from years of devastating violence imposed by the Indonesian and US governments. In this class students will get an essential overview of the culture and history of East Timor. We will learn about Nova's sister school in Manatuto- East Timor and what further assistance they need to rebuild their school and community. We will plan and carry out activities to raise awareness about the plight of people in our sister school and East Timor in general. Our class will also plan, prepare, and raise money for another to the sister school in Manatuto, East Timor. We hope to take our second trip next year as the current political situation may make a trip too risky this year. The prime focus of the class will be to learn about the needs of East Timor and our sister school, assist them as much as possible and maintain our connection with them via letters and other exchanges.  Other key activities will include watching videos about East Timor, corresponding with students in our sister school, as well as listening to a little of their music, stories and poems. We will also continue to sell fair trade East Timorese coffee, and carry out activities to raise money for our school, including concerts, video showings art shares and benefits. In addition, we will also hear from guest speakers knowledgeable about East Timor.  Please join us in this international adventure, one that will help folks much in need! Note: This class is also a good way to complete a lot of the 60 service learning hours that are required to graduate",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Occ. Education").id }],
			:category => Category.find_by_category_name("Occ. Education").id
		},
		{
			:name => "Hey You, Get Buff!",
			:facilitator => 'Joseph',
			:learning_objectives => "We will teach students the basics of stretching and warming up, lifting for different results (such as definition or bulk) and muscle groups. We will work with students to develop an individualized program in order to allow them to achieve the results they desire. We will stress safety and health and try to make the class fun, mutually encouraging and non-competitive. As part of the class we will also examine how muscles, body types and \"buffness\" are viewed in society, as well as how these things affect young people and the way in which they view themselves. Students will be expected to lift regularly in class, as well as to lift outside of class for at least two hours per week. The outside lifting will be documented via log sheets.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Physical Education").id }],
			:category => Category.find_by_category_name("Physical Education").id
		},
		{
			:name => "Hip Hop and Science",
			:facilitator => 'Nehamiah',
			:learning_objectives => "One of my passions other than teaching is music, specifically hip-hop.  The \"early days\" of hip-hop's lyrical content was rich with scientific references.  Therefore, it is a great platform to discuss science using the metaphors, similes and other references found in the lyrics.  We will analyze hip-hop lyrics and discuss the meaning.  Furthermore, we will learn the science that relates to the reference.  Additionally, we will write poetry with scientific references.  Lastly, we will be able to explain the scientific references.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Genetics",
			:facilitator => 'Susan',
			:learning_objectives => "Human genetics is fascinating. This class has a base in cell biology and will cover the fundamentals of the cell. With an understanding of cell mechanics and reproduction, you will explore genetics. You will look at how genes are made and how they make us who we are. This class is research and project based.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Nova Farm",
			:facilitator => 'Susan',
			:learning_objectives => "Nova has an amazing garden that is cared for and harvested by the Nova community. This class gives you a chance to be part of this garden. There is plenty to do on the farm. You will be able to help design and care for the garden. There are also many projects to be done. This fall we will be finishing the greenhouse and doing major work on paths and plots. You will also contemplate the role of gardens in our city and the benefits of staying organic. This class will be project and research based. Attendance is vital for the care of the garden.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Chemistry",
			:facilitator => 'Eyva',
			:learning_objectives => "This course is an algebra-based experiential journey through the essential themes, concepts, models, laboratory skills, mathematics and thinking processes that characterize a molecular understanding of the world. This class emphasizes creating a context for chemistry by understanding the history, philosophy, multiethnic perspectives, ethics, applications and relevance of chemistry. Chemistry is a study of the atomic theory, the structure of matter, bonding, nuclear chemistry, fuel chemistry, the periodic table, stoichiometry, reaction chemistry, equilibrium, kinetics, oxidation-reduction chemistry and more. These reactions and concepts explain and control the environment, product manufacturing, the human body, scientific arts like photography and ceramics, food, fermentation and combustion! Expect labs, color changes, burning stuff, and fun! We will also discuss pressing chemical issues and chemical ethics. There is math and writing in this course so get ready to use your whole brain!",
			:credits => [{:hours=>1, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Religion and Science",
			:facilitator => 'Nehamiah',
			:learning_objectives => "Religion and science are two very interesting topics, which have had profound affects on ethics.  I find it easier to understand the world's past, present and future by looking at things from another viewpoint.  We will be discussing how different religions have viewed science and therefore used or misused science.  In addition to exploring the differences, we will discuss the science involved, so we can understand the cause and effect of these decisions.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Nemo and the Nekton",
			:facilitator => 'Susan',
			:learning_objectives => "You will explore the bright colors of the coral reef. You'll study a range of organisms from amazing invertebrates to the different fish that inhabit the reef, and the adaptations they have for survival. From the reef, we'll move to the open ocean and look at every thing from plankton to porpoises. This class is a lab activity and project class. Attendance is vital for lab activities.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Society and Natural Selection",
			:facilitator => 'Nehamiah',
			:learning_objectives => "This will be a two-part class.  First we will discuss social biology.  The main idea of social biology is how genes affect the social evolution of species (mainly we will discuss humans).  Secondly, we will discuss how science has been used to negatively and positively affect our society (ie. Racial purification and propaganda).  Be prepared to think, work, discuss, write, create and achieve.",
			:credits => [{:hours=>1, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Planet Earth",
			:facilitator => 'Susan',
			:learning_objectives => "All parts of the earth are intertwined. In this course you will explore the cycles of the earth and how they relate. You'll look at earth's structures and features, volcanoes, oceans, plate tectonics. We'll discuss the atmosphere and the role of humans in the changes it's undergoing. This class will involve research and projects surrounding Earth Science.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Ecology: Conservation Projects",
			:facilitator => 'Nehamiah',
			:learning_objectives => "Our ecosystem is very fragile and susceptible to many harmful substances, which humans are the main contributors.  We as responsible recipients of the ecosystems many resources, have the responsibility to sustain the ecosystem.  Therefore, we will learn about the ecosystem and individually or in groups create conservation projects.  Although, we will learn some core functions of the ecosystem, we will be very open to a variety of conservation projects (As long as you can make the connections (explain and show understanding) and how your conservation project helps the ecosystem, \"it's a go\").",
			:credits => [{:hours=>1, :subject=> Credit.find_by_course_name("Science").id }],
			:category => Category.find_by_category_name("Science").id
		},
		{
			:name => "Projects Class",
			:facilitator => 'Melissa',
			:learning_objectives => "The Projects Class is a self-directed course where students decide what they want to learn and how they'll learn it utilizing the classroom and the community outside of school as your work areas. Students design their own curriculum, share their project plans, (students may utilize an outside resource person), create a project and produce a product and documentation portfolio, and present and defend their project to the class. This is a structured class with clearly defined expectations, goals, and timelines that also provides unlimited freedom in the design and implementation of the learning project. The student will determine the amount and categories of credit and the project planning team based on completion of the overall course competencies and competencies specific to each project.",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("TBD").id }],
			:category => Category.find_by_category_name("Seminar").id
		},
		{
			:name => "Seeds of Conflict: Crisis in the Middle East",
			:facilitator => 'Melissa',
			:learning_objectives => "What aspects of the Middle East do you want to learn more about? Students will identify the major issues, events, people, cultural and social phenomena you are most interested in examining and analyzing. The course is also intended for gaining deeper understanding of historical conflicts and current state of affairs within the region. How far back do the crises go? What has been the U.S.' role in the region? We will focus on primary sources, journal articles, and analyze news coverage. Suggested topics include (but are not limited to): religion, politics, cultural attitudes, economics, warfare, and struggles for homeland. The course involves a medium-to-heavy load of reading, research and discussion, and requires completion of a final project and presentations.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Social Studies").id }],
			:category => Category.find_by_category_name("Social Studies").id
		},
		{
			:name => "Goddesses, Chariots and Pyramids!",
			:facilitator => 'Joseph',
			:learning_objectives => "Were early humans peaceful or violent, egalitarian or male dominant? How did people dress and eat, what were their every day lives like?  Why did great civilizations rise and fall during the first chapters or our human story, what was the same and different about the ancient world as compared to our own, in which ancient society would you prefer to live? How do the patterns and discoveries set forth in the ancient world continue to influence us today? These are a few of the key issues that we will grapple with during this class concerning our early human ancestors. Although the facilitators have particular issues we want to explore, we will agree on the themes and key questions democratically as a class. Tentatively, the class will be divided into four units 1) human beginnings, hunter gathers and the emergence of agriculture, 2) the rise of \"civilization\" city states and empires in different parts of the world 3) the interaction of different culture areas and the fall of civilizations and 4) sources and lasting legacies of the ancient world's great culture areas. This class will provide lots of room for students to explore interests and topics of interest, while building the skills of historical inquiry. It should prove to be an adventure of exploration and student staff collaboration, one that will challenge all who participate to look at things in a new way.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Social Studies").id }],
			:category => Category.find_by_category_name("Social Studies").id
		},
		{
			:name => "Religions of Asia: Culture/ History of Hinduism, Buddhism, Taoism and Confucianism",
			:facilitator => 'Varvara',
			:learning_objectives => "The philosophy and practice of every Eastern religion is both embedded in the culture in which it arose and, at the same time, transcends that culture as it explores the most basic issues facing human beings at all times. This course will explore both the cultural and transcendent aspects of Eastern Religions. We will use a variety of methodologies and media to help get clearly at their driving forces and philosophies: film, workshops in flower arranging( ikebana) tea ceremony (chado), feng shui, acupuncture I ching, museum trips and art/drama projects will be used to make these very old ideas as current as the evening news.  As the questions that concern these religions arise out of their experiences from a specific peoples, this study is also a historical journey, as well as a philosophic one. Readings from original texts will be combined with contemporary sources to provide both the poetry of ancient thought with the clarity of modern scholarship.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("Social Studies").id }],
			:category => Category.find_by_category_name("Social Studies").id
		},
		{
			:name => "U.S. History 11A & 11B",
			:facilitator => 'Melissa',
			:learning_objectives => "This is a 1.0 credit course that covers all of U.S. history in one semester. It is a project, theme and competencies-based class where we identify, explore, and analyze major issues, events, people, and cultural, social, and political movements. We will concentrate on themes, concepts, conflicts, and patterns of resistance and change within a critical multicultural framework. This course requires research, group work, exhibitions, small group and class discussions, and a final project and presentations. Reading and writing will focus on primary source documents, journal articles, and fiction and non-fiction narratives.",
			:credits => [{:hours=>1, :subject=> Credit.find_by_course_name("Social Studies").id }],
			:category => Category.find_by_category_name("Social Studies").id
		},
		{
			:name => "September 11: What happened, why did it happen and where do we go from here?",
			:facilitator => 'Joseph',
			:learning_objectives => "The attacks upon the World Trade Centers and the Pentagon on September 11, 2001 were events that produced earthshaking consequences in the US and around the world.  Did the attacks take place in the manner reported by the major US news media? Were Osama Bin Laden and his followers indeed responsible for these brutal murders? Did the US government do all they reasonably could to avert the attacks, or did the US bungle its sincere attempts to stop this incidence of terrorism? On the other hand, was the US government itself part of planning the attacks or at least involved in them in some way, perhaps in making sure nothing was done to avert them? How has September 11 affected US civil liberties, Muslim Americans and the way we see politics? How and why are the events around September 11 viewed differently in various countries and regions around the world? What are some of the roots of the disagreements between the US and the Muslim world that helped lead to the many conflicts in which our government is currently engaged? What are some likely directions for our country and our world as a result of September 11th and how can we get effectively involved in shaping these future events? These are a just a few of the questions we will examine in this class which will investigate and discover key aspects of US Government and Economics as well as modern world history through the lens of the events of September 11th and the reaction to them. We will emphasize fact checking and looking at various perspectives in an attempt to get at these questions. Class activities will include personal student reflection, research and writing concerning many different perspectives concerning 9/11, organizing panels of knowledgeable speakers from various viewpoints, as well as involving ourselves in community activities relating to September 11 the wars in Iraq and Afghanistan and other aspects US foreign policy",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("American Government and Economics 12").id }],
			:category => Category.find_by_category_name("Social Studies").id
		},
		{
			:name => "Independent Social Studies",
			:facilitator => 'Joseph',
			:learning_objectives => "If you have an interest in a particular area of history or government, you are welcome to work out a field of independent study with Joe. Also, if you are engaging in foreign travel and would like to relate it to history or other types of social studies for credit or engage in activism you may be able to work out an independent social studies contract with Joe. Independent social studies contracts in the past few years have focused on things such as travel to Italy and Latin America, American Government and Economics, fair trade alternatives, globalization, mythology, world religions, environmental activism, African History, the History of the Celts and Incas and Amish, as well as the history of women in different parts of the world. This year the Northwest Social Forum will unite progressive activists from over the world who are working solve problems of pollution, racism, human rights and environmental degradation – students who get involved in this or similar community activities can earn credit for their efforts.",
			:credits => [{:hours=>0, :subject=> Credit.find_by_course_name("Social Studies").id }],
			:category => Category.find_by_category_name("Social Studies").id
		},
		{
			:name => "Beginning to Intermediate Spanish",
			:facilitator => 'Joseph',
			:learning_objectives => "We will focus on the basics of verbal and written Spanish and emphasize speaking and hearing Spanish constantly in and out of class. We'll use the book and workbook \"Ven Conmigo\" as a jumping off point. However, we will also involve students in projects on things they are interested in such as music, sports, poetry, visual art, contemporary culture and current events in Spain and Latin America. Students will spend about 30 minutes each day of speaking and listening; the rest of the time they will spend working on written material and projects while Joe teaches the other level. Occasionally the two levels will do things together.  In addition, we will have visits from native speakers of Spanish, from whom we will hear different accents and learn about various countries and cultures. We hope to plan a trip to Guatemala where students can study with Guatemalan teachers one on one. Nova has taken students to Guatemala twice in the past five years and the trips were a big success. The trip is likely to take place in April and will last about two weeks.  We also hope to take field trips to restaurants and other places where there are lots of Spanish speakers with whom we can practice.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("World Languages").id }],
			:category => Category.find_by_category_name("World Languages").id
		},
		{
			:name => "Le Francais au Debut (Beginning French)",
			:facilitator => 'Varvara',
			:learning_objectives => "This class is designed to immerse you in French language and encourage an understanding of French speaking cultures. We will connect our language study to other disciplines through films, interactive games, imaginative exercises, music, cooking and reading.  You will also have the opportunity to relate to guest speakers from various French speaking communities in Seattle. You will soon be barking in French, as well as shouting out French slogans at the next globalization demonstration.",
			:credits => [{:hours=>1, :subject=> Credit.find_by_course_name("World Languages").id }],
			:category => Category.find_by_category_name("World Languages").id
		},
		{
			:name => "Le Francais au Moyen (Intermediate French)",
			:facilitator => 'Varvara',
			:learning_objectives => "On the Intermediate level we will use French to study cinema, artistic movements and selected literature of France and the francophone world. We will focus on writing, speaking, reading and learning more complex grammatical structures. We will look together at themes and techniques of some of the more renown French directors, particularly New Wave directors.  We will explore selected artistic movement of the twentieth and twenty-first centuries. Students will choose a French filmmaker of their choice to do a personal project, a French artist and write an original illustrated children's story in French. Students this year will have the opportunity to travel with me to France for two weeks in the spring to attend a French lycee,  stay in a French family and visit Paris. Students intending to go on this trip will participate in fund raising activities, as well.",
			:credits => [{:hours=>1, :subject=> Credit.find_by_course_name("World Languages").id }],
			:category => Category.find_by_category_name("World Languages").id
		},
		{
			:name => "Le Francais Avance (Advanced French)",
			:facilitator => 'Varvara',
			:learning_objectives => "We will deepen oral, reading and writing skills by selecting various topics either in current events or history. We will explore these themes either by reading selected literary works or texts, viewing art, films, listening to news broadcasts, and discussing them. Independent work must be done outside of class, due to limited contact time. Likewise, advanced students will also have the opportunity to travel to France with me to attend a lycee, reside in a French family and visit Paris this spring. Fund raising will be expected to help reduce costs.",
			:credits => [{:hours=>0.5, :subject=> Credit.find_by_course_name("World Languages").id }],
			:category => Category.find_by_category_name("World Languages").id
		} ]
		
		
		admin = User.find(:first, :conditions => "privilege = #{User::PRIVILEGE_ADMIN}")
		
		log = File.new("contracts.csv", "w")
		log << "\"Contract Name\",\"Contract ID\",\"Facilitator\",\"Facilitator ID\"\n" 
		puts "making class contracts"
		contracts.each do |c|
		  
		  fac = User.find(:first, :conditions => "first_name = '#{c[:facilitator]}' and privilege >= #{User::PRIVILEGE_STAFF}")
		  if fac.nil?
		    puts "Stupid contract: #{c[:name]}"
		    next
		  end
			contract = Contract.new(:name => c[:name],
				:learning_objectives => c[:learning_objectives])
			contract.term = Term.find_by_name("Fall 2006")
			contract.creator = fac
			contract.contract_status = Contract::STATUS_ACTIVE
			contract.public = true
			contract.enrolling = true
			contract.category = Category.find(c[:category])
			contract.credits = Credit.empty_credits
			c[:credits].each do |credit|
				contract.credits << Credit.credit_hash(credit[:subject], credit[:hours])
			end
			contract.timeslots = ClassPeriod.empty_timeslots
			contract.save!
			Enrollment.enroll_facilitator(contract, fac, admin)
			
			log << "\"#{contract.name}\",#{contract.id},\"#{contract.facilitator.name}\",#{contract.facilitator.id}\n" 
		end
		

		puts "making coor contracts"
		cat_coor = Category.find_by_category_name("COOR")
		coordinators = [
		    User.find(:first, :conditions => "last_name = 'Barth' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Brown' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Cherniak' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Cox' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Franklin' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Grueber' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'McKittrick' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Merrell' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Morrison' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Murphy' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Osborne' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Park' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Perry' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Richardson' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Robertson' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Szwaja' and privilege>=#{User::PRIVILEGE_STAFF}"), 
        User.find(:first, :conditions => "last_name = 'Winet' and privilege>=#{User::PRIVILEGE_STAFF}")  ]
    
		coordinators.each do |s|
			fac = s
			contract = Contract.new(:name => "COOR: #{s.full_name}")
			contract.term = Term.find_by_name("COOR/2006")
			contract.creator = fac
			contract.contract_status = Contract::STATUS_ACTIVE
			contract.public = false
			contract.enrolling = true
			contract.category = cat_coor
			contract.credits = Credit.empty_credits
			contract.timeslots = [{}]
			contract.save!
			Enrollment.enroll_facilitator(contract, fac, admin)
			
			log << "\"#{contract.name}\",#{contract.id},\"#{contract.facilitator.name}\",#{contract.facilitator.id}\n" 
		end
		
		log.close
		
		
		return if false == do_enrollments
				
		puts "making enrollments"
		# Create a batch of dummy enrollments in each contract.
		# variable 1-5 kids per contract
		# variable grouping of names - always consecutive within
		# batch
		
		log = File.new("enrollments.csv", "w")
		log << "\"Contract Name\",\"Contract ID\",\"Enrollment ID\",\"Student Name\",\"Student ID\"\n" 
		
		admin = User.find(1)
		students = User.student_users
		nStudents = students.length
		Contract.find(:all, :include => [:category], :conditions => "categories.category_name = 'Mathematics' or categories.category_name = 'Language Arts' or categories.category_name = 'Science'").each do |c|
			nEnrollment = 3 #  rand(5)+1
			nRangeStart = rand(nStudents-nEnrollment+1)
			aEnrollRange = students[nRangeStart..nRangeStart+nEnrollment-1]
			aEnrollRange.each do |u| 
				e = Enrollment.enroll_student(c, u, admin)
				e.enrollment_status = Enrollment::STATUS_ENROLLED
				e.save!
				log << "\"#{c.name}\",#{c.id},\"#{e.participant.name}\",#{e.participant.id}\n" 
			end
		end
		
		coors = Contract.find(:all, :include => [:category], :conditions => "categories.category_name = 'COOR'")
		nCoors = coors.length
		User.student_users.each do |u|
			nEnrollment = 1 #  rand(5)+1
			n = rand(nCoors-nEnrollment)
			c = coors[n]
			e = Enrollment.enroll_student(c, u, admin) 
			e.enrollment_status = Enrollment::STATUS_ENROLLED
			e.save!
			log << "\"#{c.name}\",#{c.id},\"#{u.name}\",#{u.id}\n" 
		end
		
		log.close
	
	end
	
	def self.down
	
	end
end