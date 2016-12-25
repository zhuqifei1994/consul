require 'rails_helper'

feature 'Ballots' do

  let!(:user) { create(:user, :level_two) }
  let!(:budget)  { create(:budget, phase: "balloting") }
  let!(:group)   { create(:budget_group, budget: budget, name: "Group 1") }
  let!(:heading) { create(:budget_heading, group: group, name: "Heading 1", price: 1000000) }

  context "Voting" do

    background do
      login_as(user)
      visit budget_path(budget)
    end

    context "Group and Heading Navigation" do

      scenario "Groups" do
        city      = create(:budget_group, budget: budget, name: "City")
        districts = create(:budget_group, budget: budget, name: "Districts")

        visit budget_path(budget)

        expect(page).to have_link "City"
        expect(page).to have_link "Districts"
      end

      scenario "Headings" do
        city      = create(:budget_group, budget: budget, name: "City")
        districts = create(:budget_group, budget: budget, name: "Districts")

        city_heading1     = create(:budget_heading, group: city,      name: "Investments Type1")
        city_heading2     = create(:budget_heading, group: city,      name: "Investments Type2")
        district_heading1 = create(:budget_heading, group: districts, name: "District 1")
        district_heading2 = create(:budget_heading, group: districts, name: "District 2")

        visit budget_path(budget)
        click_link "City"

        expect(page).to have_link "Investments Type1"
        expect(page).to have_link "Investments Type2"

        visit budget_path(budget)
        click_link "Districts"

        expect(page).to have_link "District 1"
        expect(page).to have_link "District 2"

      end

      scenario "Investments" do
        city      = create(:budget_group, budget: budget, name: "City")
        districts = create(:budget_group, budget: budget, name: "Districts")

        city_heading1     = create(:budget_heading, group: city,      name: "Investments Type1")
        city_heading2     = create(:budget_heading, group: city,      name: "Investments Type2")
        district_heading1 = create(:budget_heading, group: districts, name: "District 1")
        district_heading2 = create(:budget_heading, group: districts, name: "District 2")

        city_investment1      = create(:budget_investment, :selected, heading: city_heading1)
        city_investment2      = create(:budget_investment, :selected, heading: city_heading1)
        district1_investment1 = create(:budget_investment, :selected, heading: district_heading1)
        district1_investment2 = create(:budget_investment, :selected, heading: district_heading1)
        district2_investment1 = create(:budget_investment, :selected, heading: district_heading2)

        visit budget_path(budget)
        click_link "City"
        click_link "Investments Type1"

        expect(page).to have_css(".budget-investment", count: 2)
        expect(page).to have_content city_investment1.title
        expect(page).to have_content city_investment2.title

        visit budget_path(budget)

        click_link "Districts"
        click_link "District 1"

        expect(page).to have_css(".budget-investment", count: 2)
        expect(page).to have_content district1_investment1.title
        expect(page).to have_content district1_investment2.title

        visit budget_path(budget)
        click_link "Districts"
        click_link "District 2"

        expect(page).to have_css(".budget-investment", count: 1)
        expect(page).to have_content district2_investment1.title
      end

      scenario "Redirect to first heading if there is only one" do
        city      = create(:budget_group, budget: budget, name: "City")
        districts = create(:budget_group, budget: budget, name: "Districts")

        city_heading      = create(:budget_heading, group: city,      name: "City")
        district_heading1 = create(:budget_heading, group: districts, name: "District 1")
        district_heading2 = create(:budget_heading, group: districts, name: "District 2")

        city_investment = create(:budget_investment, :selected, heading: city_heading)

        visit budget_path(budget)
        click_link "City"

        expect(page).to have_content city_investment.title
      end

    end

    context "Adding and Removing Investments" do

      scenario "Add a proposal", :js do
        investment1 = create(:budget_investment, :selected, budget: budget, heading: heading, group: group, price: 10000)
        investment2 = create(:budget_investment, :selected, budget: budget, heading: heading, group: group, price: 20000)

        visit budget_path(budget)
        click_link "Group 1"

        add_to_ballot(investment1)

        expect(page).to have_css("#amount-spent", text: "€10,000")
        expect(page).to have_css("#amount-available", text: "€990,000")

        within("#sidebar") do
          expect(page).to have_content investment1.title
          expect(page).to have_content "€10,000"
        end

        add_to_ballot(investment2)

        expect(page).to have_css("#amount-spent", text: "€30,000")
        expect(page).to have_css("#amount-available", text: "€970,000")

        within("#sidebar") do
          expect(page).to have_content investment2.title
          expect(page).to have_content "€20,000"
        end
      end

      scenario "Removing a proposal", :js do
        investment = create(:budget_investment, :selected, budget: budget, heading: heading, group: group, price: 10000)
        ballot = create(:budget_ballot, user: user, budget: budget)
        ballot.investments << investment

        visit budget_path(budget)
        click_link group.name

        expect(page).to have_content investment.title
        expect(page).to have_css("#amount-spent", text: "€10,000")
        expect(page).to have_css("#amount-available", text: "€990,000")

        within("#sidebar") do
          expect(page).to have_content investment.title
          expect(page).to have_content "€10,000"
        end

        within("#budget_investment_#{investment.id}") do
          find('.remove a').trigger('click')
        end

        expect(page).to have_css("#amount-spent", text: "€0")
        expect(page).to have_css("#amount-available", text: "€1,000,000")

        within("#sidebar") do
          expect(page).to_not have_content investment.title
          expect(page).to_not have_content "€10,000"
        end
      end

    end

    #Break up or simplify with helpers
    context "Balloting in multiple headings" do

      scenario "Independent progress bar for headings", :js do
        city      = create(:budget_group, budget: budget, name: "City")
        districts = create(:budget_group, budget: budget, name: "Districts")

        city_heading      = create(:budget_heading, group: city,      name: "All city",   price: 10000000)
        district_heading1 = create(:budget_heading, group: districts, name: "District 1", price: 1000000)
        district_heading2 = create(:budget_heading, group: districts, name: "District 2", price: 2000000)

        investment1 = create(:budget_investment, :selected, heading: city_heading,      price: 10000)
        investment2 = create(:budget_investment, :selected, heading: district_heading1, price: 20000)
        investment3 = create(:budget_investment, :selected, heading: district_heading2, price: 30000)

        visit budget_path(budget)
        click_link "City"

        add_to_ballot(investment1)

        expect(page).to have_css("#amount-spent",     text: "€10,000")
        expect(page).to have_css("#amount-available", text: "€9,990,000")

        within("#sidebar") do
          expect(page).to have_content investment1.title
          expect(page).to have_content "€10,000"
        end

        visit budget_path(budget)
        click_link "Districts"
        click_link "District 1"

        expect(page).to have_css("#amount-spent", text: "€0")
        expect(page).to have_css("#amount-spent", text: "€1,000,000")

        add_to_ballot(investment2)

        expect(page).to have_css("#amount-spent",     text: "€20,000")
        expect(page).to have_css("#amount-available", text: "€980,000")

        within("#sidebar") do
          expect(page).to have_content investment2.title
          expect(page).to have_content "€20,000"

          expect(page).to_not have_content investment1.title
          expect(page).to_not have_content "€10,000"
        end

        visit budget_path(budget)
        click_link "City"

        expect(page).to have_css("#amount-spent",     text: "€10,000")
        expect(page).to have_css("#amount-available", text: "€9,990,000")

        within("#sidebar") do
          expect(page).to have_content investment1.title
          expect(page).to have_content "€10,000"

          expect(page).to_not have_content investment2.title
          expect(page).to_not have_content "€20,000"
        end

        visit budget_path(budget)
        click_link "Districts"
        click_link "District 2"

        expect(page).to have_content("You have active votes in another heading")
      end
    end

    scenario "Display progress bar after first vote", :js do
      investment = create(:budget_investment, :selected, heading: heading, price: 10000)

      visit budget_investments_path(budget, heading_id: heading.id)

      expect(page).to have_content investment.title
      add_to_ballot(investment)

      within("#progress_bar") do
        expect(page).to have_css("#amount-spent", text: "€10,000")
      end
    end
  end

  context "Groups" do
    let!(:districts_group)    { create(:budget_group, budget: budget, name: "Districts") }
    let!(:california_heading) { create(:budget_heading, group: districts_group, name: "California") }
    let!(:new_york_heading)   { create(:budget_heading, group: districts_group, name: "New York") }
    let!(:investment)         { create(:budget_investment, :selected, heading: california_heading) }

    background do
      login_as(user)
    end

    scenario 'Select my heading', :js do
      visit budget_path(budget)
      click_link "Districts"
      click_link "California"

      add_to_ballot(investment)

      visit budget_path(budget)
      click_link "Districts"

      expect(page).to have_content "California"
      expect(page).to have_css("#budget_heading_#{california_heading.id}.active")
    end

    scenario 'Change my heading', :js do
      investment1 = create(:budget_investment, :selected, heading: california_heading)
      investment2 = create(:budget_investment, :selected, heading: new_york_heading)

      ballot = create(:budget_ballot, user: user, budget: budget)
      ballot.investments << investment1

      visit budget_investments_path(budget, heading_id: california_heading.id)

      within("#budget_investment_#{investment1.id}") do
        find('.remove a').trigger('click')
      end

      visit budget_investments_path(budget, heading_id: new_york_heading.id)

      add_to_ballot(investment2)

      visit budget_path(budget)
      click_link "Districts"
      expect(page).to have_css("#budget_heading_#{new_york_heading.id}.active")
      expect(page).to_not have_css("#budget_heading_#{california_heading.id}.active")
    end

    scenario 'View another heading' do
      investment = create(:budget_investment, :selected, heading: california_heading)

      ballot = create(:budget_ballot, user: user, budget: budget)
      ballot.investments << investment

      visit budget_investments_path(budget, heading_id: new_york_heading.id)

      expect(page).to_not have_css "#progressbar"
      expect(page).to have_content "You have active votes in another heading:"
      expect(page).to have_link california_heading.name, href: budget_investments_path(budget, heading: california_heading)
    end

  end

  context 'Showing the ballot' do
    scenario "Do not display heading name if there is only one heading in the group (example: group city)" do
      visit budget_path(budget)
      click_link group.name
      # No need to click on the heading name
      expect(page).to have_content("Investment projects with scope: #{heading.name}")
      expect(current_path).to eq(budget_investments_path(budget))
    end

    scenario 'Displaying the correct count & amount' do
      group1 = create(:budget_group, budget: budget)
      group2 = create(:budget_group, budget: budget)

      heading1 = create(:budget_heading, name: "District 1", group: group1, price: 100)
      heading2 = create(:budget_heading, name: "District 2", group: group2, price: 50)

      ballot = create(:budget_ballot, user: user, budget: budget)

      investment1 = create(:budget_investment, :selected, price: 10, heading: heading1, group: group1)
      investment2 = create(:budget_investment, :selected, price: 10, heading: heading1, group: group1)

      investment3 = create(:budget_investment, :selected, price: 5,  heading: heading2, group: group2)
      investment4 = create(:budget_investment, :selected, price: 5,  heading: heading2, group: group2)
      investment5 = create(:budget_investment, :selected, price: 5,  heading: heading2, group: group2)

      create(:budget_ballot_line, ballot: ballot, investment: investment1, group: group1)
      create(:budget_ballot_line, ballot: ballot, investment: investment2, group: group1)

      create(:budget_ballot_line, ballot: ballot, investment: investment3, group: group2)
      create(:budget_ballot_line, ballot: ballot, investment: investment4, group: group2)
      create(:budget_ballot_line, ballot: ballot, investment: investment5, group: group2)

      login_as(user)
      visit budget_ballot_path(budget)

      expect(page).to have_content("You have voted 5 proposals")

      within("#budget_group_#{group1.id}") do
        expect(page).to have_content "#{group1.name} - #{heading1.name}"
        expect(page).to have_content "Amount spent €20"
        expect(page).to have_content "You still have €80 to invest"
      end

      within("#budget_group_#{group2.id}") do
        expect(page).to have_content "#{group2.name} - #{heading2.name}"
        expect(page).to have_content "Amount spent €15"
        expect(page).to have_content "You still have €35 to invest"
      end
    end

  end

  scenario 'Removing spending proposals from ballot', :js do
    ballot = create(:budget_ballot, user: user, budget: budget)
    investment = create(:budget_investment, :selected, price: 10, heading: heading, group: group)
    create(:budget_ballot_line, ballot: ballot, investment: investment, heading: heading, group: group)

    login_as(user)
    visit budget_ballot_path(budget)

    expect(page).to have_content("You have voted one proposal")

    within("#budget_investment_#{investment.id}") do
      find(".remove-investment-project").trigger('click')
    end

    expect(current_path).to eq(budget_ballot_path(budget))
    expect(page).to have_content("You have voted 0 proposals")
  end

  scenario 'Removing spending proposals from ballot (sidebar)', :js do
    investment1 = create(:budget_investment, :selected, price: 10000, heading: heading)
    investment2 = create(:budget_investment, :selected, price: 20000, heading: heading)

    ballot = create(:budget_ballot, budget: budget, user: user)
    ballot.investments << investment1 << investment2

    login_as(user)
    visit budget_investments_path(budget, heading_id: heading.id)

    expect(page).to have_css("#amount-spent", text: "€30,000")
    expect(page).to have_css("#amount-available", text: "€970,000")

    within("#sidebar") do
      expect(page).to have_content investment1.title
      expect(page).to have_content "€10,000"

      expect(page).to have_content investment2.title
      expect(page).to have_content "€20,000"
    end

    within("#sidebar #budget_investment_#{investment1.id}_sidebar") do
      find(".remove-investment-project").trigger('click')
    end

    expect(page).to have_css("#amount-spent", text: "€20,000")
    expect(page).to have_css("#amount-available", text: "€980,000")

    within("#sidebar") do
      expect(page).to_not have_content investment1.title
      expect(page).to_not have_content "€10,000"

      expect(page).to have_content investment2.title
      expect(page).to have_content "€20,000"
    end
  end

  context 'Permissions' do

    scenario 'User not logged in', :js do
      investment = create(:budget_investment, :selected, heading: heading)

      visit budget_investments_path(budget, heading_id: heading.id)

      within("#budget_investment_#{investment.id}") do
        find("div.ballot").hover
        expect(page).to have_content 'You must Sign in or Sign up to continue.'
        expect(page).to have_selector('.in-favor a', visible: false)
      end
    end

    scenario 'User not verified', :js do
      unverified_user = create(:user)
      investment = create(:budget_investment, :selected, heading: heading)

      login_as(unverified_user)
      visit budget_investments_path(budget, heading_id: heading.id)

      within("#budget_investment_#{investment.id}") do
        find("div.ballot").hover
        expect(page).to have_content 'Only verified users can vote on proposals'
        expect(page).to have_selector('.in-favor a', visible: false)
      end
    end

    scenario 'User is organization', :js do
      org = create(:organization)
      investment = create(:budget_investment, :selected, heading: heading)

      login_as(org.user)
      visit budget_investments_path(budget, heading_id: heading.id)

      within("#budget_investment_#{investment.id}") do
        find("div.ballot").hover
        expect_message_organizations_cannot_vote
      end
    end

    scenario 'Unselected investments' do
      investment = create(:budget_investment, heading: heading)

      login_as(user)
      visit budget_investments_path(budget, heading_id: heading.id, unfeasible: 1)

      expect(page).to_not have_css("#budget_investment_#{investment.id}")
    end

    scenario 'Investments with feasibility undecided are not shown' do
      investment = create(:budget_investment, feasibility: "undecided", heading: heading)

      login_as(user)
      visit budget_investments_path(budget, heading_id: heading.id)

      within("#budget-investments") do
        expect(page).to_not have_css("div.ballot")
        expect(page).to_not have_css("#budget_investment_#{investment.id}")
      end
    end

    scenario 'Different district', :js do
      california = create(:budget_heading, group: group)
      new_york = create(:budget_heading, group: group)

      bi1 = create(:budget_investment, :selected, heading: california)
      bi2 = create(:budget_investment, :selected, heading: new_york)

      ballot = create(:budget_ballot, budget: budget, user: user)
      ballot.investments << bi1

      login_as(user)
      visit budget_investments_path(budget, heading: new_york)

      within("#budget_investment_#{bi2.id}") do
        find("div.ballot").hover
        expect(page).to have_content('already voted a different heading')
        expect(page).to have_selector('.in-favor a', visible: false)
      end
    end

    scenario 'Insufficient funds (on page load)', :js do
      california = create(:budget_heading, group: group, price: 1000)

      bi1 = create(:budget_investment, :selected, heading: california, price: 600)
      bi2 = create(:budget_investment, :selected, heading: california, price: 500)

      ballot = create(:budget_ballot, budget: budget, user: user)
      ballot.investments << bi1

      login_as(user)
      visit budget_investments_path(budget, heading_id: california.id)

      within("#budget_investment_#{bi2.id}") do
        find("div.ballot").hover
        expect(page).to have_content('Price is higher than the available amount left')
        expect(page).to have_selector('.in-favor a', visible: false)
      end
    end

    scenario 'Insufficient funds (added after create)', :js do
      california = create(:budget_heading, group: group, price: 1000)

      bi1 = create(:budget_investment, :selected, heading: california, price: 600)
      bi2 = create(:budget_investment, :selected, heading: california, price: 500)

      login_as(user)
      visit budget_investments_path(budget, heading_id: california.id)

      within("#budget_investment_#{bi1.id}") do
        find("div.ballot").hover
        expect(page).to_not have_content('Price is higher than the available amount left')
        expect(page).to have_selector('.in-favor a', visible: true)
      end

      add_to_ballot(bi1)

      within("#budget_investment_#{bi2.id}") do
        find("div.ballot").hover
        expect(page).to have_content('Price is higher than the available amount left')
        expect(page).to have_selector('.in-favor a', visible: false)
      end

    end

    scenario 'Insufficient funds (removed after destroy)', :js do
      california = create(:budget_heading, group: group, price: 1000)

      bi1 = create(:budget_investment, :selected, heading: california, price: 600)
      bi2 = create(:budget_investment, :selected, heading: california, price: 500)

      ballot = create(:budget_ballot, budget: budget, user: user)
      ballot.investments << bi1

      login_as(user)
      visit budget_investments_path(budget, heading_id: california.id)

      within("#budget_investment_#{bi2.id}") do
        find("div.ballot").hover
        expect(page).to have_content('Price is higher than the available amount left')
        expect(page).to have_selector('.in-favor a', visible: false)
      end

      within("#budget_investment_#{bi1.id}") do
        find('.remove a').trigger('click')
        expect(page).to have_css ".add a"
      end

      within("#budget_investment_#{bi2.id}") do
        find("div.ballot").hover
        expect(page).to_not have_content('Price is higher than the available amount left')
        expect(page).to have_selector('.in-favor a', visible: true)
      end
    end

    scenario 'Insufficient functs (removed after destroying from sidebar)', :js do
      california = create(:budget_heading, group: group, price: 1000)

      bi1 = create(:budget_investment, :selected, heading: california, price: 600)
      bi2 = create(:budget_investment, :selected, heading: california, price: 500)

      ballot = create(:budget_ballot, budget: budget, user: user)
      ballot.investments << bi1

      login_as(user)
      visit budget_investments_path(budget, heading_id: california.id)

      within("#budget_investment_#{bi2.id}") do
        find("div.ballot").hover
        expect(page).to have_content('Price is higher than the available amount left')
        expect(page).to have_selector('.in-favor a', visible: false)
      end

      within("#budget_investment_#{bi1.id}_sidebar") do
        find('.remove-investment-project').trigger('click')
      end

      expect(page).to_not have_css "#budget_investment_#{bi1.id}_sidebar"

      within("#budget_investment_#{bi2.id}") do
        find("div.ballot").hover
        expect(page).to_not have_content('Price is higher than the available amount left')
        expect(page).to have_selector('.in-favor a', visible: true)
      end
    end

    scenario "Balloting is disabled when budget isn't in the balotting phase", :js do
      budget.update(phase: 'on_hold')

      california = create(:budget_heading, group: group, price: 1000)
      bi1 = create(:budget_investment, :selected, heading: california, price: 600)

      login_as(user)

      visit budget_investments_path(budget, heading_id: california.id)
      within("#budget_investment_#{bi1.id}") do
        expect(page).to_not have_css("div.ballot")
      end
    end
  end


end


