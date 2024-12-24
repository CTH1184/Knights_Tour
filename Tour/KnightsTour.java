public class KnightsTour {

    public static void printBoard(int[][] chessboard) {


        // System.out.print("\033\143");

        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {

                if (chessboard[i][j] < 10) {
                    System.out.print("0");
                }

                System.out.print(chessboard[i][j] + " ");
            }
            System.out.println();
        }
    }


    public static void knightsTour(int[][] chessboard, int starting_x_pos, int starting_y_pos) {
        // set the starting position
        int x = starting_x_pos;
        int y = starting_y_pos;

        boolean done = false;

        int[][] moves = new int[25][8];
        int[][] possible_moves = new int[25][8];
        int[] move_LUT_x = {1,-1,-2,-2,-1,1,2,2};
        int[] move_LUT_y = {2,2,1,-1,-2,-2,-1,1};


        for (int i = 0; i < 25; i++) {
            for (int j = 0; j < 8; j++) {
                possible_moves[i][j] = 1;
            }
        }

        int moveIndex = 0;
        int previousMoveIndex = 0;


        while (!done) {

            // add the current position to the board.
            chessboard[y][x] = (moveIndex + 1);

            // if we have reached index 24, end the loop.
            if (moveIndex == 24) {
                done = true;
                break;
            }


            // clear the current move index
            for (int i = 0; i < 8; i++) {
                moves[moveIndex][i] = 0;
            }

            // a flag of sorts. if this variable stays as -1, we didn't find a valid move for this position, and we must backtrack.
            int foundMoveIndex = -1;

            // if we are moving forwards, then we erase our previous guesses about possible moves
            if (moveIndex > previousMoveIndex) {
                for (int i = 0; i < 8; i++) {
                    possible_moves[moveIndex][i] = 1;
                }
            }

            // look for possible moves.
            for (int i = 0; i < 8; i++) {
                if ((possible_moves[moveIndex][i] == 0)) {
                    continue;
                }

                if ((x + move_LUT_x[i] < 0) || (x + move_LUT_x[i] > 4)) {
                    continue;
                }

                if ((y + move_LUT_y[i] < 0) || (y + move_LUT_y[i] > 4)) {
                    continue;
                }

                if (chessboard[y + move_LUT_y[i]][x + move_LUT_x[i]] != 0) continue;

                foundMoveIndex = i;
                break;
            }

            // backtrack if we could not find a move.
            if (foundMoveIndex == -1) {
                previousMoveIndex = moveIndex--;
                for (int i = 0; i < 8; i++) {
                    if (moves[moveIndex][i] == 1) {
                        chessboard[y][x] = 0;
                        x -= move_LUT_x[i];
                        y -= move_LUT_y[i];
                        possible_moves[moveIndex][i] = 0;
                        break;
                    }
                }

                continue;
            }


            // push a new move onto the move list.
            moves[moveIndex][foundMoveIndex] = 1;
            x += move_LUT_x[foundMoveIndex];
            y += move_LUT_y[foundMoveIndex];
            previousMoveIndex = moveIndex++;
        }
    };

    public static void main(String[] args) {

        // create the array
        int[][] chessboard = new int[5][5];

        // set each square to 0 (unvisited).
        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {
                chessboard[i][j] = 0;
            }
        }

        knightsTour(chessboard, 4, 2);
        printBoard(chessboard);
    }
}
