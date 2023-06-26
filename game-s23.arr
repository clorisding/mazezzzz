use context essentials2021
# load the project support code

include shared-gdrive("dcic-2021", "1wyQZj_L0qqV9Ekgr9au6RX2iqt2Ga8Ep")
include shared-gdrive("project-2-support-fall-2022", "1vDKhda2-jwmnT_MFG2LV7KPkum1govhk") 
include reactors


   # uncomment this part when you are ready to load from Google Sheets
   
# the URL of the Google Configuration Sheet to use for your maze
ssid = "1F7an-nJq1s_DltpnMm1M0-b2Amc7JIAu7zKIY9Eqm_8"
# load maze from spreadsheet into List<List<String>>
maze-grid  = load-maze(ssid) 
# load item positions from spreadsheet into Table
item-table = load-items(ssid) 
portal-table-0 = item-table.filter-by("name", lam(x): x == "Wormhole" end)
portal-table = portal-table-0.add-column("id", range(0, portal-table-0.length()))
computer = item-table.filter-by("name", lam(x): x == "Computer" end).row-n(0)

# load all item/background-component images
floor-img  = load-texture("tile.png")
wall-img   = load-texture("wall.png")
superhero-img  = load-texture("alien.png")
computer-img = load-texture("computer.png")
popcorn-img = load-texture("popcorn.png")
tickets-img =load-texture("tickets.png")
wetfloorsign-img =load-texture("wetfloorsign.png")
wormhole-img = load-texture("wormhole.png")
    
# Define your GameState datatype here (along with any
#   supporting datatypes that you need)
data GameState: 
  | game(character-x :: Number, character-y :: Number, portal-num :: Number, portal-state-table :: Table)
end


# Define the starting configuration of your GameState
cell-size = 30
hero-position-x = 45
hero-position-y = 45

small-maze = 
  [list: 
    [list: "x", "x", "o", "x"],
    [list: "x", "o", "o", "x"],
    [list: "x", "o", "x", "x"],
    [list: "x", "o", "x", "x"],
  ] 


# Convert cell number to image coordinate.
fun cell-to-coordinate(x :: Number) -> Number:
  (x + 0.5) * cell-size
  
where:
  cell-to-coordinate(0) is 15
  cell-to-coordinate(4) is 135
end


# Convert image coordinate to cell number.
fun coordinate-to-cell(x :: Number) -> Number:
  num-round((x / cell-size) - 0.5)
  
where:
  coordinate-to-cell(15) is 0
  coordinate-to-cell((3 * 30) + 15) is 3
  coordinate-to-cell(cell-to-coordinate(4)) is 4
end


# Draw the background image
fun background-maze(maze :: List<List<String>>) -> Image:

  fun x-o-change(wall :: String) -> Image:
    doc: "'x' and 'o' represents as different colors of squares indicating the path character can go through; transform all the xo into squares"
    if wall == "x":
      square(30, "solid", "salmon")
    else:
      square(30, "solid", "peach-puff")
    end
  end

  fun maze-square(maze-list :: List<List<String>>) -> List<Image>:
    doc:"then image aligned them into a whole image"

    cases (List) maze-list:
      | empty => empty
      | link(fst, rst) =>
        link(maze-line(fst.map(x-o-change)), maze-square(rst))
    end

  end

  fun maze-line(maze-line-list :: List<Image>) -> Image:
    doc:"generate the previous function output (a list of images) into a image line"
    cases (List) maze-line-list:
      | empty => empty-image
      | link(fst, rst) =>
        beside-align("center", fst, maze-line(rst))
    end
  end

  fun maze-wall(maze-lines :: List<Image>) -> Image:
    doc:"combine the image lines into a whole image which is the background image we want for the game"
    cases (List) maze-lines:
      | empty => empty-image
      | link(fst, rst) =>
        above-align("center", fst, maze-wall(rst))
    end
  end
  
  bg = maze-wall(maze-square(maze))
  # draw the exit computer 
  place-image(computer-img, cell-to-coordinate(computer["x"]), cell-to-coordinate(computer["y"]), bg)
end


#Put wormholes into the original maze BACKGROUND
fun draw-portal(background :: Image, portals :: Table) -> Image:
  doc:"Draw portals onto the background image given the item table."
  fun helper-portal(x :: List<Number>, y :: List<Number>, scene :: Image) -> Image:
    cases(List) x:
      | empty => scene
      | link(x-f, x-r) => 
        cases(List) y:
          | empty => scene
          | link(y-f, y-r) => 
            helper-portal(x-r, y-r, place-image(wormhole-img, cell-to-coordinate(x-f), cell-to-coordinate(y-f), scene))
        end
    end
  
  end
  
  x-list = portals.get-column('x')
  y-list = portals.get-column('y')
  helper-portal(x-list, y-list, background)
end

# *** All functions above are returning images. Functions below start to include testing. ***

# Init the game including the game state, portal state and the background.
BACKGROUND = background-maze(maze-grid)
init-state = game(hero-position-x, hero-position-y, 0, portal-table)


# Define draw-game: for starters, just drop 
# the superhero somewhere (to make sure the reactor is working)
fun draw-game(state :: GameState) -> Image:
  img1 = place-image(superhero-img, state.character-x, state.character-y, draw-portal(BACKGROUND, state.portal-state-table))
  img2 = place-image(text("Portals: " + num-to-string(state.portal-num), 24, "Black"), 950, 30, img1)
  if (coordinate-to-cell(state.character-x) == computer["x"]) and (coordinate-to-cell(state.character-y) == computer["y"]):
    place-image(text("CONGRATS, YOU WIN!", 80, "green"), 500, 300, img2)
  else:
    img2
  end
end


# check if the game state is not beyond the boundary and not colliding with walls.
fun is-state-valid(state :: GameState) -> Boolean:
  cell-x = coordinate-to-cell(state.character-x)
  cell-y = coordinate-to-cell(state.character-y)
  # invalid if the position is beyond the maze boundary horizontally
  if (cell-x < 0) or (cell-x >= maze-grid.get(0).length()):
    false
  # invalid if the position is beyond the maze boundary vertically
  else if (cell-y < 0) or (cell-y >= maze-grid.length()):
    false
  # invalid if the position is within the maze boundary but the cell is located at a wall
  else if maze-grid.get(cell-y).get(cell-x) == "x":
    false
  else:
    true
  end
where:
  is-state-valid(game(-1, 0, 0, portal-table)) is false
  is-state-valid(game(0, -1, 0, portal-table)) is false
  is-state-valid(game(0, 585, 0, portal-table)) is false
  is-state-valid(game(1065, 0, 0, portal-table)) is false
  is-state-valid(game(15, 15, 0, portal-table)) is false
end


# find if there is a portal and the portal id given the current cell position of the hero.
fun find-portal(cell-x :: Number, cell-y :: Number, portal-x :: List<Number>, portal-y :: List<Number>, id :: List<Number>) -> Number:
  # portal-x, portal-y, and id are the three columns in the portal-state-table. We use recursion to find if the query cell position is the same as one of the portal's position. If no portal is found, return -1, else return the portal's id in the table.
  cases(List) portal-x:
    | empty => -1
    | link(x-f, x-r) => 
    cases(List) portal-y:
      | empty => -1
      | link(y-f, y-r) => 
          cases(List) id:
            | empty => -1
            | link(id-f, id-r) => 
              # check if the query cell position is the same as one of the portal's position 
              if (cell-x == x-f) and (cell-y == y-f):
                # return the portal's id in the table
                id-f
              else:
                # use recursion to continue the search in the rest of the lists x-r, y-r, id-r (the rest list of portal-x, portal-y, and id correspondingly)
                find-portal(cell-x, cell-y, x-r, y-r, id-r)
              end
          end
      end
    end
where:
  find-portal(8, 8, portal-table.get-column("x"), portal-table.get-column("y"), portal-table.get-column("id")) is 0
  find-portal(2, 8, portal-table.get-column("x"), portal-table.get-column("y"), portal-table.get-column("id")) is 1
  find-portal(10, 20, portal-table.get-column("x"), portal-table.get-column("y"), portal-table.get-column("id")) is -1
end


# Update game state given the new position of the hero. Check the portals.
fun update-game-state(position-x :: Number, position-y :: Number, state :: GameState, clicked :: Boolean) -> GameState:
  cell-x = coordinate-to-cell(position-x)
  cell-y = coordinate-to-cell(position-y)
  # find if there is a portal at the new position of the next game state. -1 indicates not found.
  found = find-portal(cell-x, cell-y, state.portal-state-table.get-column("x"), state.portal-state-table.get-column("y"), state.portal-state-table.get-column("id"))
  
  if found == -1:
    if clicked:
      # if no portal at the new position but the mouse is clicked meaning we get to the next game state using portal not keyboard movement, reduce the portal count by one but can't go negative
      game(position-x, position-y, num-max(0, state.portal-num - 1), state.portal-state-table)
    else:
      # no teleport, no portal collected, simply moving by keyboard, the most regular case.
      game(position-x, position-y, state.portal-num, state.portal-state-table)
    end
  else:
    if clicked:
      # if we teleport to the new position where there is another portal, we consume a portal and immediately gain a new one, so the portal count doesn't change.
      game(position-x, position-y, state.portal-num, state.portal-state-table.filter-by("id", lam(x): not(x == found) end)) 
    else:
      # if we move to a new position where there is a portal using keyboard, we the portal count increments by one.
      game(position-x, position-y, state.portal-num + 1, state.portal-state-table.filter-by("id", lam(x): not(x == found) end)) 
    end
  end
end


# Define key-pressed: for starters, just make the superhero
# move, even if not on the grid positions (to make 
# sure the reactor is working)
fun key-pressed(state :: GameState, key :: String) -> GameState:
  # precompute the next game state if key is pressed for up or down or left or right 
  up-state = update-game-state(state.character-x, state.character-y - cell-size, state, false)
  down-state = update-game-state(state.character-x, state.character-y + cell-size, state, false)
  left-state = update-game-state(state.character-x - cell-size, state.character-y, state, false)
  right-state = update-game-state(state.character-x + cell-size, state.character-y, state, false)
  # check if the precomputed state corresponding to the key is a valid state, otherwise the game state remains unchanged.
  if ((key == 'up') or (key == 'w')) and is-state-valid(up-state):
    up-state
  else if ((key == 'down') or (key == 's')) and is-state-valid(down-state):
    down-state
  else if ((key == 'left') or (key == 'a')) and is-state-valid(left-state):
    left-state
  else if ((key == 'right') or (key == 'd')) and is-state-valid(right-state):
    right-state
  else:
    state
  end
where:
  # wrong key
  key-pressed(game(hero-position-x, hero-position-y, 0, portal-table), "i") is game(hero-position-x, hero-position-y, 0, portal-table)
  # hit wall
  key-pressed(game(hero-position-x, hero-position-y, 0, portal-table), "up") is game(hero-position-x, hero-position-y, 0, portal-table)
  # hit another wall
  key-pressed(game(hero-position-x, hero-position-y, 0, portal-table), "down") is game(hero-position-x, hero-position-y, 0, portal-table)
  # go
  key-pressed(game(hero-position-x, hero-position-y, 0, portal-table), "right") is game(hero-position-x + 30, hero-position-y, 0, portal-table)
  # pick portal and update portal table
  key-pressed(game(cell-to-coordinate(7), cell-to-coordinate(8), 1, portal-table), "right") is game(cell-to-coordinate(8), cell-to-coordinate(8), 2, portal-table.filter-by("id", lam(x): not(x == 0) end))
  # portal picked already, no longer there
  key-pressed(game(cell-to-coordinate(7), cell-to-coordinate(8), 1, portal-table.filter-by("id", lam(x): not(x == 0) end)), "right") is game(cell-to-coordinate(8), cell-to-coordinate(8), 1, portal-table.filter-by("id", lam(x): not(x == 0) end))
end


# check if the two points are within the range.
fun within-range(x1 :: Number, y1 :: Number, x2 :: Number, y2 :: Number) -> Boolean:
  valid-range = 200
  if num-sqrt(((x1 - x2) * (x1 - x2)) + ((y1 - y2) * (y1 - y2))) < valid-range:
    true
  else:
    false
  end
where:
  within-range(100, 40, 200, 70) is true
  within-range(100, 40, 1200, 70) is false
end


# Define the mouse click event for portal
fun mouse-clicked(state :: GameState, x :: Number, y :: Number, event :: String) -> GameState:
  mouse-cell-x = coordinate-to-cell(x)
  mouse-cell-y = coordinate-to-cell(y)
  state-cell-x = coordinate-to-cell(state.character-x)
  state-cell-y = coordinate-to-cell(state.character-y)
  # if the mouse is clicked and I have portals and the click position is not the same as my current position, then I update the new game state with the new click position if it's within the move range, otherwise the game state remains unchanged.
  if (event == "button-up") and (state.portal-num > 0) and not((mouse-cell-x == state-cell-x) and (mouse-cell-y == state-cell-y)):
    new-state = update-game-state(cell-to-coordinate(mouse-cell-x), cell-to-coordinate(mouse-cell-y), state, true)
    if within-range(state.character-x, state.character-y, new-state.character-x, new-state.character-y) and is-state-valid(new-state):
      new-state
    else:
      state
    end
  else:
    state
  end
  
where:
  # no collected portals
  mouse-clicked(game(hero-position-x, hero-position-y, 0, portal-table), hero-position-x + 30, hero-position-y, "button-up") is game(hero-position-x, hero-position-y, 0, portal-table)
  # click on the wall, don't use portal
  mouse-clicked(game(hero-position-x, hero-position-y, 1, portal-table), hero-position-x, hero-position-y + 30, "button-up") is game(hero-position-x, hero-position-y, 1, portal-table)
  # click out-of-range
  mouse-clicked(game(hero-position-x, hero-position-y, 1, portal-table), hero-position-x + 200, hero-position-y, "button-up") is game(hero-position-x, hero-position-y, 1, portal-table)
  # click on another portal
  mouse-clicked(game(cell-to-coordinate(7), cell-to-coordinate(8), 1, portal-table), cell-to-coordinate(8), cell-to-coordinate(8), "button-up") is game(cell-to-coordinate(8), cell-to-coordinate(8), 1, portal-table.filter-by("id", lam(x): not(x == 0) end))
  # click on the same cell (not necessarily the cell center)
  mouse-clicked(game(hero-position-x, hero-position-y, 1, portal-table), hero-position-x + 10, hero-position-y, "button-up") is game(hero-position-x, hero-position-y, 1, portal-table)
  # click on a valid spot but not exactly on the cell center.
  mouse-clicked(game(hero-position-x, hero-position-y, 1, portal-table), hero-position-x + 16, hero-position-y, "button-up") is game(hero-position-x + 30, hero-position-y, 0, portal-table)
  # no clicking, just moving mouse
  mouse-clicked(game(hero-position-x, hero-position-y, 0, portal-table), 100, 100, "moving") is game(hero-position-x, hero-position-y, 0, portal-table)
end


# Game complete condition
fun game-complete(state :: GameState) -> Boolean:
  if (coordinate-to-cell(state.character-x) == computer["x"]) and (coordinate-to-cell(state.character-y) == computer["y"]):
    true
  else:
    false
  end
where:
  game-complete(game(1035, 435, 0, portal-table)) is true
  game-complete(game(100, 200, 0, portal-table)) is false
end


maze-game =
  reactor:
    init              : init-state,
    to-draw           : draw-game,
    on-mouse          : mouse-clicked, # portals only
    on-key            : key-pressed,
    stop-when         : game-complete, # [optional]
    title             : "Superhero Escape"
  end
  

interact(maze-game)


#| Reflection
   1. The advantage of using a 2D list is that it's easy to access any indexed cell with i-th row and j-th column by calling maze-grid.get(i).get(j). We don't need to make a table with column names. The disadvantage is that we can only extract a row from the list, e.g. the 1st row maze-grid.get(0), but we can't extract a column while table can. 
   2. Google Sheet is straightforward for human to view and edit but it's difficult for Pyret functions to directly access. The list-of-list is good for functions to access but not visually straightforward for us to inspect. Image is the most straightforward media for us to view but it's hard for programs to read.
   3. I used my own datatype solution which I keep record of the character's current position on the image, the number of portals collected so far, and a table of available portals yet to be collected.
   4. It is important to identify what component in the program is dynamic and what are static. In this project, all dynamic elements should be organized in the game state datatype and all static parts can be simply treated as the background. Think thoroughly how the dynamic parts could change and also how the dynamic parts could interact with each other as well as the static components. This greatly helped me to come up with corner cases for testing the functions.
   5. It took me a few trials to incorporate the portals in my program. At first, I used a separate datatype to record the portals but I found I need to update the portal states along with the game state and it's not straightforward to do so with separate datatypes. After I include portal states as a member of the game state. I realized I need to update the content of the portal table because once a portal is consumed, it should no longer be available. I tried to add a boolean "used" column to portal-table but I can't easily change the value inside the table, so I decided to add a "id" column to help me find the specific portal given a position and I can use table filter function to remove that portal from the table easily. I also realized when I click the mouse to try using the portal to teleport to my current hero position, the portal shouldn't be consumed, so I added a check to verify if the mouse click is at the same cell as where the hero is currently.
   6. I found as more and more component I added to the datatype, it gets more and more clumsy. I wonder if I need to implement something with a lots of attribute in the data, how could I organize them elegantly as a class. Besides, if I want some functions which are closely related to the data to have direct access to the members of the datatype without passing the data as input to the function, how can I manage the scope of the data access for different functions?
|#





