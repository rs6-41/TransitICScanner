import SwiftUI

struct ScrapingFormView: View {
    @State var name:String = ""
    @State var isBirthday:Bool = false
    @State var iscaptcha:Bool = false
    @State var isID:Bool = false
    @Binding var card: String
    @Binding var birthdayMonth: String
    @Binding var birthdayDay: String
    @Binding var captcha: String
    @Binding var ID:String
    @Binding var isLoaded: Bool
    @Binding var error: Bool
    @Binding var errorMessage: String
    @Binding var isLoading: Bool
    @State var cardLimit:Int = 16
    @State var captchaLimit:Int = 6
    @State var idLimit:Int = 4
    var controller: WebViewController
    var onSubmit: () -> Void

    var body: some View {
        Form {
            Section(
                header:Text(LocalizedStringKey("form.card.title")),
                footer:Text(LocalizedStringKey("form.card.description"))
            ){
                TextField(LocalizedStringKey("form.card"), text: $card)
                    .keyboardType(.numberPad)
                    .onChange(of: card) {
                        if card.count > cardLimit {
                            card = String(card.prefix(cardLimit))
                        }
                    }
            }
            if isBirthday {
                Section(
                    header:Text(LocalizedStringKey("form.birthday.title")),
                    footer:Text(LocalizedStringKey("form.birthday.description"))
                ){
                    HStack {
                        TextField(LocalizedStringKey("form.birthday.month"), text: $birthdayMonth)
                            .keyboardType(.numberPad)
                            .onChange(of: birthdayMonth) {
                                let limit = 2
                                if birthdayMonth.count > limit {
                                    birthdayMonth = String(birthdayMonth.prefix(limit))
                                }
                            }
                        Divider()
                        TextField(LocalizedStringKey("form.birthday.day"), text: $birthdayDay)
                            .keyboardType(.numberPad)
                            .onChange(of: birthdayDay) {
                                let limit = 2
                                if birthdayDay.count > limit {
                                    birthdayDay = String(birthdayDay.prefix(limit))
                                }
                            }
                    }
                }
            }
            if iscaptcha {
                Section(
                    header:Text(LocalizedStringKey("form.captcha.title"))
                ){
                    VStack(alignment:.leading) {
                        if let image = controller.captchaImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width:250)
                                .padding(.bottom,5)
                                .onAppear() {
                                    isLoaded = true
                                }
                        } else {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .onAppear() {
                                        isLoaded = false
                                    }
                                Spacer()
                            }
                        }
                        TextField(LocalizedStringKey("form.captcha"), text: $captcha)
                            .keyboardType(.numberPad)
                            .onChange(of: captcha) {
                                if captcha.count > captchaLimit {
                                    captcha = String(captcha.prefix(captchaLimit))
                                }
                            }
                    }
                }
                .listSectionSpacing(15)
            }
            
            if isID {
                Section(
                    header:Text(LocalizedStringKey("form.ID.title")),
                    footer:Text(LocalizedStringKey("form.ID.description"))
                ){
                    TextField(LocalizedStringKey("form.ID"), text: $ID)
                        .keyboardType(.numberPad)
                        .onChange(of: ID) {
                            if ID.count > idLimit {
                                ID = String(ID.prefix(idLimit))
                            }
                        }
                }
            }
            
            Section() {
                Button(action: {
                    onSubmit()
                }) {
                    Text(LocalizedStringKey("form.done"))
                        .bold()
                        .padding()
                        .frame(maxWidth:.infinity,maxHeight:30)
                }
                .disabled(!isLoaded)
                .buttonStyle(GlassProminentButtonStyle())
                .frame(maxWidth:400,alignment:.center)
            }
            .listRowInsets(
                .init(top: .zero,leading: .zero,bottom: .zero,trailing: .zero)
            )
            .listRowBackground(Color.clear)
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

#Preview {
    ScrapingFormView(
        card: .constant(""),
        birthdayMonth: .constant(""),
        birthdayDay: .constant(""),
        captcha: .constant(""),
        ID: .constant(""),
        isLoaded: .constant(false),
        error: .constant(false),
        errorMessage: .constant(""),
        isLoading: .constant(false),
        controller: WebViewController(),
        onSubmit: {print("")}
    )
}
