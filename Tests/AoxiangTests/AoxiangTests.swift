@testable import Aoxiang
import XCTest

final class AoxiangTests: XCTestCase {
    var server: HTTPServer!

    override func setUp() async throws {
        server = HTTPServer()
        try server.start(8080)
    }

    override func tearDown() {
        server.stop()
    }

//    func testExample() throws {
//        // create the expectation
//        let _ = expectation(description: "delay")
//
//        waitForExpectations(timeout: 30)
//
//        XCTAssertNotEqual(server.socket?.sock, -1)
//    }

    func test404() async throws {
        let res = await fetch("/404")
        XCTAssertEqual(res, "404 Not Found")
    }

    func testAsync() async throws {
        server.get("/async") { _, res async in
            res.send("hello")
        }

        let getRes = await fetch("/async")
        XCTAssertEqual(getRes, "hello")
    }

    func testSampleResponse() async throws {
        server.get("/") { _, res in
            res.send("Index")
        }

        server.get("/getTest") { _, res in
            res.send("hello")
        }

        server.post("/postTest") { _, res in
            res.send("hello")
        }
        
        server.get("/data") { _, res in
            res.send("data".data(using: .utf8)!)
        }

        let indexRes = await fetch("/", method: "GET")
        XCTAssertEqual(indexRes, "Index")
        let getRes = await fetch("/getTest", method: "GET")
        XCTAssertEqual(getRes, "hello")
        let postRes = await fetch("/postTest", method: "POST")
        XCTAssertEqual(postRes, "hello")
        let data = await fetch("/data", method: "GET")
        XCTAssertEqual(data, "data")
    }

    func testRquest() async throws {
        server.post("/postParams") { req, res in

            // method
            XCTAssertEqual(req.method, "POST")
            // method
            XCTAssertEqual(req.path, "/postParams")
            // query
            XCTAssertEqual(req.query.count, 1)
            XCTAssertEqual(req.query[0].0, "a")
            XCTAssertEqual(req.query[0].1, "1")

            res.send(req.body?.toString() ?? "")
        }

        let res = await fetch("/postParams?a=1", method: "POST", body: "hello")
        XCTAssertEqual(res, "hello")
    }

    func testMiddleware() async throws {
        server.get("/middleware") { _, res in
            res.send("hello")
        }

        let res = await fetch("/middleware")
        XCTAssertEqual(res, "hello")
    }

    func testStreamResponse() async throws {
        server.get("/stream") { _, res in
            res.write("hi,")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                res.write("Aoxiang.")
                res.end()
            }
        }

        // TODO：need test each chunk
        let res = await fetch("/stream")
        XCTAssertEqual(res, "hi,Aoxiang.")
    }
    
    // TODO: add tests

    func testSSE() async throws {
        server.get("/sse") { _, res in
            let target = res.sendEvents()
            target.dispatchMessage("SSE Response:")
            for i in 1 ... 10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 * Double(i)) {
                    target.dispatchMessage("chunk-\(i)")
                    if i == 10 {
                        target.close()
                    }
                }
            }
        }

        // TODO：need test each chunk
        let res = await fetch("/sse")
        XCTAssertEqual(res, "data: SSE Response:\r\n\r\ndata: chunk-1\r\n\r\ndata: chunk-2\r\n\r\ndata: chunk-3\r\n\r\ndata: chunk-4\r\n\r\ndata: chunk-5\r\n\r\ndata: chunk-6\r\n\r\ndata: chunk-7\r\n\r\ndata: chunk-8\r\n\r\ndata: chunk-9\r\n\r\ndata: chunk-10\r\n\r\ndata: \r\n\r\n")
    }
}
