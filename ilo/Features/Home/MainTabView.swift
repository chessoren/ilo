import SwiftUI

/// The main app shell: native iOS 26 Liquid Glass tab bar + a separate glass "Create" circle.
struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            Tab("Home", systemImage: "house.fill", value: AppRouter.TabID.home) {
                NavigationStack(path: $router.homePath) {
                    HomeView()
                        .navigationDestination(for: UUID.self) { id in
                            if let course = model.courses.first(where: { $0.id == id }) {
                                PathView(course: course)
                            } else {
                                MissingCourseView()
                            }
                        }
                }
            }
            Tab("Leagues", systemImage: "trophy.fill", value: AppRouter.TabID.leagues) {
                NavigationStack { LeaguesView() }
            }
            Tab("Quests", systemImage: "checklist", value: AppRouter.TabID.quests) {
                NavigationStack { QuestsView() }
            }
            .badge(model.quests.filter { $0.isDone && !$0.claimed }.count)
            Tab("Profile", systemImage: "person.crop.circle.fill", value: AppRouter.TabID.profile) {
                NavigationStack { ProfileView() }
            }
            Tab("Create", systemImage: "sparkles", value: AppRouter.TabID.create, role: createRole) {
                NavigationStack { CreateCourseView() }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Palette.ink)
        .environment(router)
        .onChange(of: router.tab) { _, _ in
            Haptics.shared.tick()
        }
        #if DEBUG
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            switch DebugSeed.requestedTab {
            case "leagues": router.tab = .leagues
            case "quests": router.tab = .quests
            case "profile": router.tab = .profile
            case "create": router.tab = .create
            case "path": if let c = model.activeCourse { router.openPath(c) }
            default: break
            }
        }
        #endif
        .fullScreenCover(item: $router.lesson) { launch in
            LessonPlayerView(course: launch.course, node: launch.node) {
                router.lesson = nil
            }
            .environment(router)
        }
        .sheet(isPresented: $router.showShop) {
            NavigationStack { ShopView() }
                .environment(router)
                .presentationDetents([.medium, .large])
        }
    }
}

/// iOS 27 renders `.prominent` as a separate glass circle; iOS 26 uses the search slot.
private var createRole: TabRole {
    if #available(iOS 27.0, *) { return .prominent }
    return .search
}

/// Shown if a pushed course was deleted meanwhile.
private struct MissingCourseView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            BloubView(shape: .circle, color: .ink, expression: .confused).frame(width: 110)
            Text("This course is gone").font(.display(22, weight: .bold))
            Button("Back home") { router.homePath = [] }
                .buttonStyle(.pill(.ink, fullWidth: false))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IloBackground())
    }
}
