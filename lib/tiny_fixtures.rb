module TinyFixtures
  CLAN_TERMS = [:fall, :spring]
  CLANS = {
    :fester => {
      :first_name => 'Micah',
      :offspring => %w{frank filbert francine floyd foobar},
      :classes => %w{homeroom language_arts social_studies independent seminar}
      },
    :hogg => {
      :first_name => 'Elijah',
      :offspring => %w{harry hank herbert huck helen},
      :classes => %w{homeroom math science independent seminar}
      },
    :myer => {
      :first_name => 'Caleb',
      :offspring => %w{mary morgan maxine medford magpie},
      :classes => %w{homeroom social_studies government independent seminar}
    }
  }
end