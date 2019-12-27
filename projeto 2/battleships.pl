:-use_module(library(clpfd)).
:-use_module(library(lists)).

:-consult('display.pl').
:-consult('data.pl').
:-consult('utils.pl').

/* constrain cell value */
constrainCell(_,0,_,0).
constrainCell(_,_,0,0).
constrainCell(_,11,_,0).
constrainCell(_,_,11,0).
constrainCell(Vars, Row, Column, Value) :-
    N is (Row-1)*10+Column,
    nth1(N, Vars, Value).

/* set margin of ship piece to 0 considering its type (north,east,west or single) */
constrainMargin(Vars, Row, Column, ShipPiece) :-
    TopRow is Row-1,
    BottomRow is Row+1,
    LeftColumn is Column-1,
    RightColumn is Column+1,
    (ShipPiece == single ->
        constrainCell(Vars, TopRow, Column, 0),      
        constrainCell(Vars, Row, LeftColumn, 0),    
        constrainCell(Vars, Row, RightColumn, 0),    
        constrainCell(Vars, BottomRow, Column, 0);
    ShipPiece == north ->
        constrainCell(Vars, TopRow, Column, 0),      
        constrainCell(Vars, Row, LeftColumn, 0),    
        constrainCell(Vars, Row, RightColumn, 0),    
        constrainCell(Vars, BottomRow, Column, 1),
    ShipPiece == east ->
        constrainCell(Vars, TopRow, Column, 0),   
        constrainCell(Vars, Row, LeftColumn, 1),
        constrainCell(Vars, Row, RightColumn, 0),   
        constrainCell(Vars, BottomRow, Column, 0);
    ShipPiece == west ->
        constrainCell(Vars, TopRow, Column, 0),      
        constrainCell(Vars, Row, LeftColumn, 0),    
        constrainCell(Vars, Row, RightColumn, 1),  
        constrainCell(Vars, BottomRow, Column, 0); 
    ShipPiece == south ->     
        constrainCell(Vars, TopRow, Column, 1),
        constrainCell(Vars, Row, LeftColumn, 0),    
        constrainCell(Vars, Row, RightColumn, 0),    
        constrainCell(Vars, BottomRow, Column, 0)).

/* fills board with initial info */
fillBoardWithInfo([], _).
fillBoardWithInfo([H|T], Vars):-
    [[Row, Column], PieceType] = H,
    N is (Row-1)*10+Column,
    (PieceType == water ->
        nth1(N, Vars, 0);
    nth1(N,Vars,1),    
    constrainMargin(Vars, Row, Column, PieceType)),
    fillBoardWithInfo(T, Vars).

/* constrain number of ship pieces there are in each row or column */
constrain([], []).
constrain([H|T], [Constraint|ConstraintsTail]) :-
    global_cardinality(H, [1-Constraint,0-_]),
    constrain(T, ConstraintsTail).

/* constrain ships so there are 10 ships on the board (1-4, 2-3, 3-2, 4-1) */
constrainShips(_, []).
constrainShips(Vars, [Ship|ShipsTail]) :-
    ship(Ax, SizeX, Ay, SizeY) = Ship,
    constrainShipX(Vars, Ax, Ay, SizeX),
    constrainShipY(Vars, Ax, Ay, SizeY),
    constrainShips(Vars, ShipsTail).

constrainShipX(_,_,_,1).
constrainShipX(Vars, Ax, Ay, SizeX) :-
    N #= (Ay-1)*10+Ax,
    nth1(N, Vars, 1),
    NewAx #= Ax+1,
    NewSizeX #= SizeX-1,
    constrainShipX(Vars, NewAx, Ay, NewSizeX).
    
constrainShipY(_,_,_,1).
constrainShipY(Vars, Ax, Ay, SizeY) :-
    N #= (Ay-1)*10+Ax,
    nth1(N, Vars, 1),
    NewAy #= Ay+1,
    NewSizeY #= SizeY-1,
    constrainShipY(Vars, Ax, NewAy, NewSizeY).

/* constrain ships to be non adjacent */
constrainDiagonals(_, 11, _).

constrainDiagonals(Board, Line, 11) :-
    BottomLine is Line+1,
    constrainDiagonals(Board, BottomLine, 1).
    
constrainDiagonals(Board, Line, Column) :-
    getValueFromMatrix(Board, Line, Column, Value),
    TopLine is Line-1,
    BottomLine is Line+1,
    LeftColumn is Column-1,
    RightColumn is Column+1,
    getValueFromMatrix(Board, TopLine, LeftColumn, TopLeft),
    getValueFromMatrix(Board, TopLine, RightColumn, TopRight),
    getValueFromMatrix(Board, BottomLine, LeftColumn, BottomLeft),
    getValueFromMatrix(Board, BottomLine, RightColumn, BottomRight),
    Value+TopLeft #=< 1,
    Value+TopRight #=< 1,
    Value+BottomLeft #=< 1,
    Value+BottomRight #=< 1,
    constrainDiagonals(Board, Line, RightColumn).

/* battleships */
battleships(ID, Vars):-
    initialBoard(Board),
    matrixToList(Board, Vars),
    domain(Vars,0,1),
    data(ID, InitialInfo, PerRowData, PerColumnData),
    fillBoardWithInfo(InitialInfo, Vars),
    % constrain rows and columns number of ship segments 
    constrain(Board, PerRowData),
    transpose(Board, BoardTransposed, 0, 10),
    constrain(BoardTransposed, PerColumnData),
    % constrain ships to be non-adjacent
    constrainDiagonals(Board, 1, 1),
    % constrain ships and their size
    StartsX = [Ax, Bx, Cx, Dx, Ex, Fx, Gx, Hx, Ix, Jx],
    StartsY = [Ay, By, Cy, Dy, Ey, Fy, Gy, Hy, Iy, Jy], 
    domain(StartsX, 1, 10),
    domain(StartsY, 1, 10),
    BattleshipWidth in {2,5},
    BattleshipHeight in {2,5},
    BattleshipWidth #\= BattleshipHeight,
    CruiserOneWidth in {2,4},
    CruiserOneHeight in {2,4},
    CruiserOneWidth #\= CruiserOneHeight,
    CruiserTwoWidth in {2,4},
    CruiserTwoHeight in {2,4},
    CruiserTwoWidth #\= CruiserTwoHeight,
    DestroyerOneWidth in {2,3},
    DestroyerOneHeight in {2,3},
    DestroyerOneWidth #\= DestroyerOneHeight,
    DestroyerTwoWidth in {2,3},
    DestroyerTwoHeight in {2,3},
    DestroyerTwoWidth #\= DestroyerTwoHeight,
    DestroyerThreeWidth in {2,3},
    DestroyerThreeHeight in {2,3},
    DestroyerThreeWidth #\= DestroyerThreeHeight,
    Ships = [
        ship(Jx, BattleshipWidth, Jy, BattleshipHeight),
        ship(Ix, CruiserOneWidth, Iy, CruiserOneHeight),
        ship(Hx, CruiserTwoWidth, Hy, CruiserTwoHeight),
        ship(Gx, DestroyerOneWidth, Gy, DestroyerOneHeight),
        ship(Fx, DestroyerTwoWidth, Fy, DestroyerTwoHeight),
        ship(Ex, DestroyerThreeWidth, Ey, DestroyerThreeHeight),
        ship(Dx, 2, Dy, 2),
        ship(Cx, 2, Cy, 2),
        ship(Bx, 2, By, 2),
        ship(Ax, 2, Ay, 2)
    ],
    Jx+BattleshipWidth-2 #=< 10, Jy+BattleshipHeight-2 #=< 10,
    Ix+CruiserOneWidth-2 #=< 10, Iy+CruiserOneHeight-2 #=< 10,
    Hx+CruiserTwoWidth-2 #=< 10, Hy+CruiserTwoHeight-2 #=< 10,
    Gx+DestroyerOneWidth-2 #=< 10, Gy+DestroyerOneHeight-2 #=< 10,
    Fx+DestroyerTwoWidth-2 #=< 10, Fy+DestroyerTwoHeight-2 #=< 10,
    Ex+DestroyerThreeWidth-2 #=< 10, Ey+DestroyerThreeHeight-2 #=< 10,
    Dx #=< 10, Dy #=< 10,
    Cx #=< 10, Cy #=< 10,
    Bx #=< 10, By #=< 10,
    Ax #=< 10, Ay #=< 10,

    % break symmetries with ships of same size
    lex_chain([[Dx,Dy],[Cx,Cy],[Bx,By],[Ax,Ay]], [op(#<),global(true)]),
    lex_chain([[Gx,Gy],[Fx,Fy],[Ex,Ey]], [op(#<),global(true)]),
    lex_chain([[Ix,Iy],[Hx,Hy]], [op(#<),global(true)]),

    disjoint2(Ships),
    !,
    % constrain ships and their size
    constrainShips(Vars, Ships),
    labeling([], Vars),
    printBoard(Board, PerRowData, PerColumnData).
    