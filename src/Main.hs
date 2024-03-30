-- Imports
import Graphics.Gloss
import Graphics.Gloss.Interface.Pure.Game
import System.Random
import Data.List (unfoldr)

-- Cell type as a boolean (True == living cell and False == dead cell)
type Cell = Bool
-- Grid as a list of lists of Cells
type Grid = [[Cell]]
-- Game state
type GameState = (Grid, Bool)

-- Fullscreen
window :: Display
window = FullScreen
-- Backround color
background :: Color
background = white
-- Cell size
cellSize :: Float
cellSize = 20
-- Grid size
gridSize :: Int
gridSize = 50



-- FUNCTIONS --

-- Generates an empty grid (all cells dead)
generateEmptyGrid :: Int -> Grid
generateEmptyGrid size = replicate size (replicate size False)



-- Converts screen coordinates into grid coordinates
screenToGrid :: (Float, Float) -> (Int, Int)
screenToGrid (screenX, screenY) = (gridX, gridY)
  where
    windowWidth = fromIntegral gridSize * cellSize
    windowHeight = fromIntegral gridSize * cellSize
    offsetX = windowWidth / 2
    offsetY = windowHeight / 2
    -- Conversion of the screen coordinates (mouse) to grid coordinates
    gridX = floor ((screenX + offsetX) / cellSize)
    gridY = floor ((screenY + offsetY) / cellSize)



-- Updates the status of a cell based on a mouse click
toggleCell :: Grid -> (Int, Int) -> Grid
toggleCell grid (x, y)
  | x >= 0 && x < gridSize && y >= 0 && y < gridSize =
      take y grid ++
      [take x (grid !! y) ++ [not (grid !! y !! x)] ++ drop (x + 1) (grid !! y)] ++
      drop (y + 1) grid
  | otherwise = grid



-- Draws the grid and takes the entire game state and extracts the grid for display
drawGrid :: GameState -> Picture
drawGrid (grid, _) = pictures [translate (fromIntegral x * cellSize - halfGridWidth) (fromIntegral y * cellSize - halfGridHeight) (drawCell cell) | (y, row) <- zip [0..] grid, (x, cell) <- zip [0..] row]
  where
    gridSizeInPixels = fromIntegral gridSize * cellSize
    halfGridWidth = gridSizeInPixels / 2
    halfGridHeight = gridSizeInPixels / 2
    drawCell True = color black $ rectangleSolid cellSize cellSize
    drawCell False = color (greyN 0.9) $ rectangleSolid cellSize cellSize



-- Counts the living neighbors of a cell at given coordinates
countLivingNeighbors :: Int -> Int -> Grid -> Int
countLivingNeighbors x y grid = length $ filter id neighbors
  where
    -- List of the relative coordinates of the eight possible neighbors
    neighborOffsets = [(-1, -1), (-1, 0), (-1, 1),
                       ( 0, -1),          ( 0, 1),
                       ( 1, -1), ( 1, 0), ( 1, 1)]
    -- Calculates the absolute coordinates of the neighbors and filters out invalid positions
    neighborPositions = [(x + dx, y + dy) | (dx, dy) <- neighborOffsets,
                                            x + dx >= 0, x + dx < gridSize,
                                            y + dy >= 0, y + dy < gridSize]
    -- Extracts the status of neighboring cells and checks whether they are alive
    neighbors = [grid !! ny !! nx | (nx, ny) <- neighborPositions]



-- Handles user input
handleInput :: Event -> GameState -> GameState
handleInput event (grid, running) =
  case event of
    -- Toggle cell state on left mouse button click
    (EventKey (MouseButton LeftButton) Up _ pos) ->
      if not running
      then (toggleCell grid (screenToGrid pos), running)
      else (grid, running)
    -- Start/stop the simulation with the space bar
    (EventKey (SpecialKey KeySpace) Up _ _) ->
      (grid, not running)
    _ -> (grid, running)



-- Updates the game when it is running
updateGame :: Float -> GameState -> GameState
-- Update only if simulation is running
updateGame _ (grid, True) = (updateGrid grid, True)
-- Do nothing if simulation is not running
updateGame _ gameState = gameState



-- Update the grid based on the Game of Life rules
updateGrid :: Grid -> Grid
updateGrid grid = [[updateCell x y | x <- [0..gridSize-1]] | y <- [0..gridSize-1]]
  where
    updateCell x y =
      let
        isAlive = grid !! y !! x
        livingNeighbors = countLivingNeighbors x y grid
        -- Determines the next state of a cell
        newState = case (isAlive, livingNeighbors) of
                     (True, 2) -> True
                     (_, 3)    -> True
                     _         -> False
      in newState



-- Main function
main :: IO ()
main = play window background 10 (generateEmptyGrid gridSize, False) drawGrid handleInput updateGame
