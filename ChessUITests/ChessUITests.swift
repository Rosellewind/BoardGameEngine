//
//  ChessUITests.swift
//  ChessUITests
//
//  Created by Roselle Tanner on 2/21/17.
//  Copyright © 2017 Roselle Tanner. All rights reserved.
//

import XCTest

class ChessUITests: XCTestCase {
        
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
    func testInCheck() {    //// just starting to test this, no asserts yet
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
    }
    
    func testInCheckMate() {    //// just starting to test this, no asserts yet
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
        sleep(8)
        
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
        sleep(3)
        XCTAssertNotNil(app.otherElements["White Pawn on D5"])
    }
    
}
