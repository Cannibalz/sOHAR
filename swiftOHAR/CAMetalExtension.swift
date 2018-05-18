extension CAMetalLayer {
    
    // Interface so user can grab this drawable at any time
    private struct nextDrawableExtPropertyData {
        static var _currentSceneDrawable : CAMetalDrawable? = nil
    }
    var currentSceneDrawable : CAMetalDrawable? {
        get {
            return nextDrawableExtPropertyData._currentSceneDrawable
        }
    }
    
    // The rest of this is just swizzling
    private static let doJustOnce : Any? = {
        print ("***** Doing the doJustOnce *****")
        CAMetalLayer.setupSwizzling()
        
        return nil
    }()
    
    public static func enableNextDrawableSwizzle() {
        _ = CAMetalLayer.doJustOnce
    }
    
    public static func setupSwizzling() {
        print ("***** Doing the setupSwizzling *****")
        
        let copiedOriginalSelector = #selector(CAMetalLayer.originalNextDrawable)
        let originalSelector = #selector(CAMetalLayer.nextDrawable)
        let swizzledSelector = #selector(CAMetalLayer.newNextDrawable)
        
        let copiedOriginalMethod = class_getInstanceMethod(self, copiedOriginalSelector)
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        
        let oldImp = method_getImplementation(originalMethod!)
        method_setImplementation(copiedOriginalMethod!, oldImp)
        
        let newImp = method_getImplementation(swizzledMethod!)
        method_setImplementation(originalMethod!, newImp)
        
    }
    
    
    @objc func newNextDrawable() -> CAMetalDrawable? {
        // After swizzling, originalNextDrawable() actually calls the real nextDrawable()
        let drawable = originalNextDrawable()
        
        // Save the drawable
        nextDrawableExtPropertyData._currentSceneDrawable = drawable
        
        return drawable
    }
    
    @objc func originalNextDrawable() -> CAMetalDrawable? {
        // This is just a placeholder. Implementation will be replaced with nextDrawable.
        // ***** This will never be called *****
        return nil
    }
}
