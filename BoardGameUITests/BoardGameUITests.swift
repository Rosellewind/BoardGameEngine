//
//  ChessUITests.swift
//  ChessUITests
//
//  Created by Roselle Tanner on 2/21/17.
//  Copyright © 2017 Roselle Tanner. All rights reserved.
//

import XCTest

class BoardGameUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    func testInCheck() {
        let app = XCUIApplication()
        app.tables.staticTexts["Chess"].tap()
        
        app.otherElements["White Pawn on F2"].tap()
        app.otherElements["F4"].tap()
        app.otherElements["Black Pawn on E7"].tap()
        app.otherElements["E5"].tap()
        app.otherElements["White Pawn on A2"].tap()
        app.otherElements["A4"].tap()
        app.otherElements["Black Queen on D8"].tap()
        app.otherElements["H4"].tap()
        XCTAssert(app.staticTexts["White is in check"].exists)
    }
    
    func testInCheckMate() {
        let app = XCUIApplication()
        app.tables.staticTexts["Chess"].tap()
        
        app.otherElements["White Pawn on H2"].tap()
        app.otherElements["H3"].tap()
        let blackPawnOnC7Element = app.otherElements["Black Pawn on C7"]
        blackPawnOnC7Element.tap()
        app.otherElements["C6"].tap()
        app.otherElements["White Pawn on F2"].tap()
        app.otherElements["F3"].tap()
        app.otherElements["Black Queen on D8"].tap()
        blackPawnOnC7Element.tap()
        app.otherElements["White Pawn on A2"].tap()
        app.otherElements["A3"].tap()
        app.otherElements["Black Queen on C7"].tap()
        app.otherElements["G3"].tap()
        
        let weHaveAWinnerAlert = app.alerts["We have a winner!"]
        XCTAssert(weHaveAWinnerAlert.exists)
    }
    
    func testPromotionThenCapture() {
        let app = XCUIApplication()
        app.tables.staticTexts["Chess"].tap()
        
        app.otherElements["White Pawn on A2"].tap()
        app.otherElements["A4"].tap()
        let blackPawnOnB7Element = app.otherElements["Black Pawn on B7"]
        blackPawnOnB7Element.tap()
        app.otherElements["B5"].tap()
        app.otherElements["White Pawn on A4"].tap()
        app.otherElements["Black Pawn on B5"].tap()
        let blackKnightOnB8Element = app.otherElements["Black Knight on B8"]
        blackKnightOnB8Element.tap()
        app.otherElements["C6"].tap()
        app.otherElements["White Pawn on B5"].tap()
        app.otherElements["B6"].tap()
        app.otherElements["Black Pawn on A7"].tap()
        app.otherElements["A6"].tap()
        app.otherElements["White Pawn on B6"].tap()
        blackPawnOnB7Element.tap()
        app.otherElements["Black Pawn on A6"].tap()
        app.otherElements["A5"].tap()
        app.otherElements["White Pawn on B7"].tap()
        blackKnightOnB8Element.tap()
        app.sheets["Promotion"].buttons["Queen"].tap()
        app.otherElements["Black Rook on A8"].tap()
        app.otherElements["White Queen on B8"].tap()
        
        XCTAssert(app.otherElements["Black Rook on B8"].exists)
        XCTAssert(!app.otherElements["White Queen on B8"].exists)
    }
    
    
    func testPawnCapture() {
        let app = XCUIApplication()
        app.tables.staticTexts["Chess"].tap()
        
        app.otherElements["White Pawn on E2"].tap()
        app.otherElements["E4"].tap()
        app.otherElements["Black Pawn on D7"].tap()
        app.otherElements["D5"].tap()
        app.otherElements["White Pawn on E4"].tap()
        app.otherElements["Black Pawn on D5"].tap()
        
        XCTAssert(app.otherElements["White Pawn on D5"].exists)
    }
    
    func testPawnPromotionToQueenInAttack_ShouldBeCheckMateAfter_EvenIfOpponentCanPutSelfInCheck() {
        // checks both: checking for checkmate after pawn promotion
        //              checking for checkmate, opponent can leave self in check
        let app = XCUIApplication()
        app.tables.staticTexts["Chess"].tap()
        
        app.otherElements["White Pawn on B2"].tap()
        app.otherElements["B4"].tap()
        let blackPawnOnC7Element = app.otherElements["Black Pawn on C7"]
        blackPawnOnC7Element.tap()
        app.otherElements["C5"].tap()
        app.otherElements["White Pawn on B4"].tap()
        app.otherElements["Black Pawn on C5"].tap()
        app.otherElements["Black Pawn on D7"].tap()
        app.otherElements["D6"].tap()
        app.otherElements["White Pawn on C5"].tap()
        app.otherElements["C6"].tap()
        let blackBishopOnC8Element = app.otherElements["Black Bishop on C8"]
        blackBishopOnC8Element.tap()
        app.otherElements["F5"].tap()
        app.otherElements["White Pawn on A2"].tap()
        app.otherElements["A3"].tap()
        app.otherElements["Black Queen on D8"].tap()
        app.otherElements["A5"].tap()
        app.otherElements["White Pawn on A3"].tap()
        app.otherElements["A4"].tap()
        app.otherElements["Black Bishop on F5"].tap()
        app.otherElements["G6"].tap()
        app.otherElements["White Pawn on C6"].tap()
        blackPawnOnC7Element.tap()
        app.otherElements["Black Queen on A5"].tap()
        app.otherElements["H5"].tap()
        app.otherElements["White Pawn on C7"].tap()
        blackBishopOnC8Element.tap()
        sleep(2)
        app.sheets["Promotion"].buttons["Queen"].tap()
        let weHaveAWinnerAlert = app.alerts["We have a winner!"]
        XCTAssert(weHaveAWinnerAlert.exists)
    }
    
}
