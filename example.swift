import SwiftUI



// View that contains ScrollView and the circle that expands on negative scroll.
struct Example: View {
    @State private var offset: CGFloat = 0
    @State private var isScrolling = false
    @State private var size: CGFloat = 26

    var body: some View {
        VStack {
            Circle()
                .frame(width: size, height: size)

            ScrollView {
                LazyVStack {
                    Text("item 1")
                    Text("item 2")
                    Text("...")
                    Text("item 999")
                }
                .modifier(ReadOffset($offset))
            }
            .UIScrollView($isScrolling)
        }
        .onChange(of: offset) {
            // This part changes the circle size.
            if $0 > 0 {
                size = 26 + $0
            }
        }
    }
}



// Reads ScrollView's content top offset.
// Source: https://www.youtube.com/watch?v=MPIdZHMZd3E
struct ReadOffset: ViewModifier {
    @Binding var offset: CGFloat

    init(_ offset: Binding<CGFloat>) {
        self._offset = offset
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy -> Color in
                    let rect = proxy.frame(in: .global)

                    DispatchQueue.main.async {
                        self.offset = rect.minY
                    }

                    return Color.clear
                }
            )
    }
}



// Adds touch down and up event to ScrollView.
// Source: https://github.com/agelessman/SwiftUI_ScrollView_Offset
extension View {
    func UIScrollView(_ isScrolling: Binding<Bool>) -> some View {
        return MyScrollViewControllerRepresentable(isScrolling: isScrolling, content: self)
    }
}


struct MyScrollViewControllerRepresentable<Content>: UIViewControllerRepresentable where Content: View {
    var isScrolling: Binding<Bool>
    var content: Content

    func makeUIViewController(context: Context) -> MyScrollViewUIHostingController<Content> {
        MyScrollViewUIHostingController(isScrolling: isScrolling, rootView: content)
    }

    func updateUIViewController(_ uiViewController: MyScrollViewUIHostingController<Content>, context: Context) {
        uiViewController.rootView = content
        uiViewController.view.setNeedsUpdateConstraints()
    }
}


class MyScrollViewUIHostingController<Content>: UIHostingController<Content>, UIScrollViewDelegate where Content: View {
    var isScrolling: Binding<Bool>
    var sv: UIScrollView?
    var ready = false
    var fixedOffset: CGFloat = 0

    init(isScrolling: Binding<Bool>, rootView: Content) {
        self.isScrolling = isScrolling
        super.init(rootView: rootView)
    }

    @objc dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        // observer is added from viewDidAppear, in order to
        // make sure the SwiftUI view is already in place
        if ready { return } // avoid running more than once
        ready = true

        sv = findScrollView(in: view)
        sv?.delegate = self
    }

    func findScrollView(in view: UIView?) -> UIScrollView? {
        if view?.isKind(of: UIScrollView.self) ?? false {
            return view as? UIScrollView
        }

        for subview in view?.subviews ?? [] {
            if let sv = findScrollView(in: subview) {
                return sv
            }
        }

        return nil
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isScrolling.wrappedValue = true
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.isScrolling.wrappedValue = false
    }
}
