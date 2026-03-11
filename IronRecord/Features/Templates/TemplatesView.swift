import SwiftUI

struct TemplatesView: View {
    @State private var templates = TemplateRowItem.mock
    @State private var templatePendingDeletion: TemplateRowItem?
    @State private var templateBeingEdited: TemplateRowItem?
    @State private var templateBeingDuplicated: TemplateRowItem?
    @State private var isAddRoutinePresented = false

    var body: some View {
        List {
            ForEach(templates) { template in
                TemplateRowView(
                    template: template,
                    onEditTapped: {
                        templateBeingEdited = template
                    },
                    onDuplicateTapped: {
                        templateBeingDuplicated = duplicatedDraft(from: template)
                    },
                    onDeleteTapped: {
                        templatePendingDeletion = template
                    }
                )
                    .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Templates")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Template", systemImage: "plus") {
                    isAddRoutinePresented = true
                }
                    .accessibilityHint("Creates a new template")
            }
        }
        .sheet(isPresented: $isAddRoutinePresented) {
            NavigationStack {
                AddTemplateView { newTemplate in
                    templates.append(newTemplate)
                }
            }
            .interactiveDismissDisabled()
        }
        .sheet(item: $templateBeingEdited) { template in
            NavigationStack {
                AddTemplateView(template: template) { updatedTemplate in
                    updateTemplate(updatedTemplate)
                }
            }
            .interactiveDismissDisabled()
        }
        .sheet(item: $templateBeingDuplicated) { template in
            NavigationStack {
                AddTemplateView(template: template, savesAsNewTemplate: true) { duplicatedTemplate in
                    templates.append(duplicatedTemplate)
                    templateBeingDuplicated = nil
                }
            }
            .interactiveDismissDisabled()
        }
        .alert(
            "Delete Template",
            isPresented: isShowingDeleteAlert,
            presenting: templatePendingDeletion
        ) { template in
            Button("Delete", role: .destructive) {
                deleteTemplate(template)
            }
            Button("Cancel", role: .cancel) { }
        } message: { template in
            Text("Delete \(template.title)? This action cannot be undone.")
        }
    }

    private var isShowingDeleteAlert: Binding<Bool> {
        Binding(
            get: { templatePendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    templatePendingDeletion = nil
                }
            }
        )
    }

    private func deleteTemplate(_ template: TemplateRowItem) {
        templates.removeAll { $0.id == template.id }
        templatePendingDeletion = nil
    }

    private func updateTemplate(_ template: TemplateRowItem) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else {
            templateBeingEdited = nil
            return
        }

        templates[index] = template
        templateBeingEdited = nil
    }

    private func duplicatedDraft(from template: TemplateRowItem) -> TemplateRowItem {
        TemplateRowItem(
            title: "\(template.title) (copy)",
            exercises: template.exercises.map { exercise in
                TemplateExerciseRowItem(
                    name: exercise.name,
                    notes: exercise.notes,
                    restSeconds: exercise.restSeconds,
                    sets: exercise.sets.map { set in
                        TemplateSetRowItem(
                            weightText: set.weightText,
                            repsText: set.repsText
                        )
                    }
                )
            }
        )
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
    }
}
