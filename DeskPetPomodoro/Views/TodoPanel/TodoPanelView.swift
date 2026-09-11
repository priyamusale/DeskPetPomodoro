import SwiftUI

struct TodoPanelView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Stars and title
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                Text("TO DO LIST")
                    .font(.kristi(size: 48))
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
            }
            .foregroundColor(Color(hex: "#4A4A4A"))
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            HStack {
                TextField("Add a new task...", text: $taskVM.newTaskText)
                    .textFieldStyle(.plain)
                    .font(.dawning(size: 20))
                    .foregroundColor(Color(hex: "#2A2A2A"))
                    .onSubmit {
                        taskVM.addTask()
                    }
                
                Button(action: { taskVM.showDatePicker.toggle() }) {
                    Image(systemName: "calendar")
                        .foregroundColor(taskVM.showDatePicker ? .blue : .gray)
                }
                .buttonStyle(.plain)
                
                if taskVM.showDatePicker {
                    DatePicker("", selection: $taskVM.newTaskDeadline, displayedComponents: .date)
                        .labelsHidden()
                        .frame(width: 100)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.4))
            .cornerRadius(6)
            .padding(.horizontal, 16)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(taskVM.tasks) { task in
                        TaskRowView(task: task)
                            .contextMenu {
                                Button(role: .destructive) {
                                    taskVM.deleteTask(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#FAFAFA"))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 2, y: 4)
        )
    }
}

struct TaskRowView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    let task: TodoTask
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color(hex: "#4A4A4A"), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(task.isCompleted ? Color(hex: "#4A4A4A") : Color.clear))
                
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.dawning(size: 20))
                    .foregroundColor(task.isCompleted ? .gray : Color(hex: "#2A2A2A"))
                    .strikethrough(task.isCompleted, color: .gray)
                
                if let deadline = task.deadline {
                    HStack {
                        Text("Due: \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        if !task.isCompleted && deadline < Date() {
                            Text("(Past Due)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                taskVM.toggleTask(task)
            }
        }
    }
}
