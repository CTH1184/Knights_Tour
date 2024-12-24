import static org.junit.Assert.assertTrue;

import org.junit.jupiter.api.Test;


public class KnightsTourTester {

    private boolean containsNoZeroes(int[][] chessboard) {
        for (int i = 0; i < chessboard.length; i++) {
            for (int j = 0; j < chessboard[i].length; j++) {
                if (chessboard[i][j] == 0) return false;
            }
        }
        return true;
    }

    private boolean verifyKnightsTour(int[][] chessboard, int starting_x, int starting_y) {


        // verify start position is correctly "1".
        if (chessboard[starting_y][starting_x] != 1) {
            return false;
        }

        int[] move_LUT_x = {1,-1,-2,-2,-1,1,2,2};
        int[] move_LUT_y = {2,2,1,-1,-2,-2,-1,1};
        int x = starting_x;
        int y = starting_y;

        for (int i = 1; i < Math.pow(chessboard.length,2); i++) {

            boolean foundNextMove = false;

            // check each possible move.
            for (int move = 0; move < 8; move++) {

                int next_y = y + move_LUT_y[move];
                int next_x = x + move_LUT_x[move];

                if (next_x < 0 || next_x > (chessboard.length - 1)) {
                    continue;
                }

                if (next_y < 0 || next_y > (chessboard[0].length - 1)) {
                    continue;
                }

                if (chessboard[y + move_LUT_y[move]][x + move_LUT_x[move]] == (i + 1)) {
                    x += move_LUT_x[move];
                    y += move_LUT_y[move];
                    foundNextMove = true;
                    break;
                }
            }

            if (!foundNextMove) {
                // board is not valid if all possible moves don't return the next number in the sequence.
                return false;
            }
        }
        return true;
    }

    @Test
    void assertKnightsTourIsValid() {

        int[][] chessboard = new int[5][5];

        for (int i = 0; i < chessboard.length; i += 2) {
            for (int j = 0; j < chessboard[0].length; j += 2) {
                System.out.println("x: " + i + " y: " + j);

                // set each square to 0 (unvisited).
                for (int k = 0; k < chessboard.length; k++) {
                    for (int m = 0; m < chessboard[0].length; m++) {
                        chessboard[k][m] = 0;
                    }
                }
                KnightsTour.knightsTour(chessboard, i, j);
                assertTrue(containsNoZeroes(chessboard));
                assertTrue(verifyKnightsTour(chessboard, i, j));
            }
        }
    }
}
