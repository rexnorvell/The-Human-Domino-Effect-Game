# The Human Domino Effect - Documentation

You have arrived at the documentation for The Human Domino Effect (HDE) game! These pages provide instructions and supplemental information for contributors to the video game branch of the HDE project. This GitHub documentation is specifically directed toward software developers and HDE product owners. However, HDE contributors of all types are encouraged to read through the information provided to better understand the overarching Human Domino Effect initiative.

## Table of Contents

-   For Software Developers
    -   Onboarding
        -   Prerequisites
        -   Trello
    -   Unit Testing
        -   Setting Up GdUnit3
        -   Creating New Tests with Godot Editor 
        -   Creating New Tests with Visual Studio Code
        -   Running Tests Locally
        -   Example Unit Tests
-   For Product Owners
    -   Onboarding New Developers
        -   Introducing Trello
        -   Adding Users to Trello
        -   Adding Users to the GitHub Organization
    -   Offboarding Developers
        -   Finalizing Work
        -   Team Cleanup
        -   Removing Users from Trello
        -   Removing Users from the GitHub Organization

## For Software Developers

### Onboarding

If you're a new developer for The Human Domino Effect, welcome to the HDE team! The following guide contains information which may be useful for your work on the game.

#### Prerequisites

The following tools are either required or recommended for all HDE software developers:

-   [Godot 3.x](https://godotengine.org/download/3.x/windows/)
-   [Git](https://git-scm.com/downloads)
-   [Visual Studio Code](https://code.visualstudio.com) (OPTIONAL) 
    -   Additional VSCode extensions are included in the HDE GitHub repository
-   [Git GUI Client](https://git-scm.com/downloads/guis) (OPTIONAL)
    -   Multiple options available; each vary in price and OS compatibility
    -   Useful for developers unfamiliar with Git and/or relevant terminal commands
    -   May or may not feature all Git CLI functionality

#### Trello

Trello is a kanban board where user stories, bugs, and other features are stored. This is where HDE developers design, plan, and organize work items.

There will likely be existing work items in the `Backlog` and `Ready for sprint` columns. Addressing bugs and other items in these columns is one of the best ways to familiarize yourself with the codebase. However, outstanding work items SHOULD NOT take priority over objectives established during your semester or whatever work period applies to you. It is the responsibility of you and/or your developer team to meet with HDE product owners and establish high-level goals together.

[Get access to the Trello board here.](https://trello.com/invite/b/kOTWV1H0/ATTIc5a4e5e5a0af6f92b8cfed6abb92e21578B3F7D0/board-game-godot)

### Unit Testing

This project utilizes GdUnit3 for testing. This is a flexible plugin for testing nodes and scenes. Before following the steps below, you should familiarize yourself with [the documentation for the GdUnit3 plugin.](https://mikeschulze.github.io/gdUnit3/)

#### Setting Up GdUnit3

-   GdUnit3 is pre-installed in this repository; no additional installation required
    -   NOTE: If HDE is migrated to Godot 4.x, GdUnit4 must be installed instead
-   In the Godot 3.x editor...
    -   Go to `Project` -> `Project Settings` -> `Plugins`
    -   Click the `Enable` checkbox for GdUnit3 under the `Status` column
-   OPTIONAL: If you're using Visual Studio Code as an external editor...
    -   Install recommended VSCode extensions. [`Godot GdUnit Test Explorer`](https://marketplace.visualstudio.com/items?itemName=mikeschulze.gdunit3) should also be included.

#### Creating New Tests with Godot Editor

-   Open the script of the node or scene you want to create a test for
-   Right click the definition of the function you wish to test...
    -   In other words, the line with `func <function_name>(...)`
-   Click on `Create Test`
-   A new file should be created using the template
-   Create new tests by writing new functions in the following format...
    -   `func test_<test_case_name>(<test parameters and cases if parameterized test>)`

#### Creating New Tests with Visual Studio Code

-   You can use the steps for making new tests in the Godot editor to create the test file in VSCode
-   Again, create new tests by writing functions in the following format...
    -   `func test_<test_case_name>(<test parameters and cases if parameterized test>)`

#### Running Tests Locally

-   In the Godot editor, a tab for GdUnit should appear
-   To execute tests, click the `Run Tests` button.
-   To debug tests, place breakpoints and click the `Debug Tests` button.

#### Example Unit Tests

We've included two HDE-specific example tests: `DominoUnitTest` and `LobbyIntegrationTest`. These tests are no longer functional, but have been left in as references.
-   To access these examples, pull up the `FileSystem` tab in the Godot editor or manually browse the contents of your HDE repository
-   Reference tests are located at `addons` -> `gdUnit3` -> `Example_Tests`

## For Product Owners

### Onboarding New Developers

As a product owner, it is your responsibility to clearly communicate your wishes for the HDE project. You're ultimately able to set goals and prioritize them as needed throughout your developers' prearranged work period.

Although you do not need programming knowledge, it's your job to ensure your objectives are feasible and result in good game features. To this end, your developer team should honestly establish its abilities and limitations. Your developers should also provide detailed feedback regarding each goal outlined by you and/or other product owners. 

Make sure to establish a regular meeting schedule with your team. Periodic (but not constant) progress checking is arguably the important factor toward you and your team's success.

#### Introducing Trello

Trello is a kanban board where user stories, bugs, and features are stored. This is where developers will design, plan, and organize work items.

There will likely be existing work items in the `Backlog` and `Ready for sprint` columns. However, these tasks should be secondary to your vision for the current work period. It is the responsibility of your new team to renegotiate high-level goals with you. New goals should be added to the Trello board as appropriate.

_While it isn't required_, it is strongly recommended to check the Trello board on a regular basis. You should confirm that your developers are focusing on what's expected. You should also clarify any questions from your developers as they may arise.

[Link to the HDE Trello board](https://trello.com/b/kOTWV1H0/board-game-godot)

#### Adding Users to Trello

While you have the HDE Trello board open, check the top right of the page for a `Share` buttton.

![Share button](<assets/2023-04-21%2017_07_48-Board%20Game%20(Godot)%20_%20Trello%20and%202%20more%20pages%20-%20Personal%20-%20Microsoft%E2%80%8B%20Edge.png>)

When this button is clicked, a small window will appear. Type in your new member's email address into the attached text box.

![Add email and share board](<assets/2023-04-21%2017_08_19-Board%20Game%20(Godot)%20_%20Trello%20and%202%20more%20pages%20-%20Personal%20-%20Microsoft​%20Edge.png>)

---

#### Adding Users to the Github Organization

This is a similar proccess to adding members to the Trello board. However, members _must_ have a GitHub account.

First, nagivate to the [Human Domino Effect GitHub organization](https://github.com/Human-Domino-Effect) and click on the `People` tab.

![People tab](assets/2023-04-21%2017_18_39-Human-Domino-Effect%20and%204%20more%20pages%20-%20Personal%20-%20Microsoft​%20Edge.png)

Once on the `People` tab, you should see a green `Invite member` button. Click this and a small window should appear.

![Invite member](assets/2023-04-21%2017_16_57-People%20·%20Human-Domino-Effect%20and%204%20more%20pages%20-%20Personal%20-%20Microsoft​%20Edge.png)

In this window, type the new member's email into the box. Their username should appear. Click on the name.

_Make sure they are being invited as a member._ This will prevent developers from having too much access to the organization.

![Input email](assets/2023-04-21%2017_17_36-People%20·%20Human-Domino-Effect%20and%204%20more%20pages%20-%20Personal%20-%20Microsoft​%20Edge.png)

Once their email is entered, you can click the `Invite` button. Repeat this for all members.

![Send invite!](assets/2023-04-21%2017_17_49-People%20·%20Human-Domino-Effect%20and%204%20more%20pages%20-%20Personal%20-%20Microsoft​%20Edge.png)

### Offboarding Developers

#### Finalizing Work

Once your developers have made final submissions (for example, a group of CS 499 students finishing their final presentation and submitting the latest version of HDE), it would be ideal to walk through all the changes made during the work period. You may also want to compare the work done to the Trello board; make sure all Trello work cards are where they're supposed to be.

#### Team Cleanup

Over the semester, the team has probably accumulated outstanding pull requests, repository branches, or other work items. These should be dealt with before they finish the semester. Make sure the team looks through the repository and ensures the next team will be working with as clean a slate as possible.

The team might have some work they would like to pass on to the next team. If this is the case, it would be worth having the team document this somewhere--new work items in Trello, documented here in the repository, or noted by hand--for the product owner(s) to pass on to the next team. The product owners should  work with both teams to make the transition of work as seamless as possible.

#### Removing Users from Trello

This process is similar to inviting users to Trello.

While you have the Trello board open, check the top right of the page for a `Share` buttton.

![Share button](<assets/2023-04-21%2017_07_48-Board%20Game%20(Godot)%20_%20Trello%20and%202%20more%20pages%20-%20Personal%20-%20Microsoft%E2%80%8B%20Edge.png>)

When this button is clicked, a small window will appear. Select the dropdown next to the user(s) you wish to remove and select `Remove from board`.

![Remove user](<assets/2023-04-21%2017_32_37-Board%20Game%20(Godot)%20_%20Trello%20and%201%20more%20page%20-%20Personal%20-%20Microsoft​%20Edge.png>)

#### Removing Users from the GitHub Organization

This is a similar proccess to removing members from the Trello board.

First, nagivate to the [Human Domino Effect GitGub organization](https://github.com/Human-Domino-Effect) and click on the `People` tab.

![People tab](assets/2023-04-21%2017_18_39-Human-Domino-Effect%20and%204%20more%20pages%20-%20Personal%20-%20Microsoft​%20Edge.png)

Once on the `People` tab, look down at the list of users and find the user(s) you wish to remove.

Select the three dots at the far right of their name and select `Remove from organization` from the dropdown. Click `Remove members` to confirm.

![Remove from org](assets/2023-04-21%2017_41_28-People%20·%20Human-Domino-Effect%20and%204%20more%20pages%20-%20Personal%20-%20Microsoft​%20Edge.png)

![Confirm](assets/2023-04-21%2017_46_56-People%20·%20Human-Domino-Effect%20and%204%20more%20pages%20-%20Personal%20-%20Microsoft​%20Edge.png)
