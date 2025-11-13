import SPFKMetadataXMP
import SPFKMetadataXMPC
import Testing

struct LifecycleTests {
    @Test func canInitialize() {
        #expect(XMPWrapper.initialize())
        #expect(XMPWrapper.isInitialized())
        XMPWrapper.terminate()
    }
}
