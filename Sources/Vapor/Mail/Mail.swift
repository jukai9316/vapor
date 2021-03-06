import SMTP
import Foundation
import Transport
import Settings

/// Defines objects capable of transmitting emails
public protocol MailProtocol {
    /// Send a single email
    func send(_ mail: Email) throws

    /// Send a batched email
    /// by default, this will iterate list
    /// and send mail individually
    /// clients that support batch proper should
    /// override this function
    func send(batch: [Email]) throws
}

extension MailProtocol {
    public func send(batch: [Email]) throws {
        try batch.forEach(send)
    }
}

/// SMTP Mailer to use basic SMTP Protocols
public final class SMTPMailer: MailProtocol {
    let host: String
    let port: Int
    let securityLayer: SecurityLayer
    let credentials: SMTPCredentials

    public init(host: String, port: Int, securityLayer: SecurityLayer, credentials: SMTPCredentials) {
        self.host = host
        self.port = port
        self.securityLayer = securityLayer
        self.credentials = credentials
    }

    public func send(_ mail: Email) throws {
        let client = try makeClient()
        try client.send(mail, using: credentials)
    }

    public func send(batch: [Email]) throws {
        let client = try makeClient()
        try client.send(batch, using: credentials)
    }

    private func makeClient() throws -> SMTPClient<TCPClientStream> {
        return try SMTPClient(host: host, port: port, securityLayer: securityLayer)
    }
}

extension SMTPMailer {
    /// https://sendgrid.com/
    ///
    /// Credentials:
    /// https://app.sendgrid.com/settings/credentials
    public static func makeSendGrid(with credentials: SMTPCredentials) -> SMTPMailer {
        return SMTPMailer(
            host: "smtp.sendgrid.net",
            port: 465,
            securityLayer: .tls(nil),
            credentials: credentials
        )
    }

    /// https://www.digitalocean.com/community/tutorials/how-to-use-google-s-smtp-server
    ///
    /// Credentials:
    /// user: Your full Gmail or Google Apps email address (e.g. example@gmail.com or example@yourdomain.com)
    /// pass: Your Gmail or Google Apps email password
    public static func makeGmail(with credentials: SMTPCredentials) -> SMTPMailer {
        return SMTPMailer(
            host: "smtp.gmail.com",
            port: 465,
            securityLayer: .tls(nil),
            credentials: credentials
        )
    }

    /// https://mailgun.com/
    ///
    /// Credentials:
    /// https://mailgun.com/app/domains
    public static func makeMailgun(with credentials: SMTPCredentials) -> SMTPMailer {
        return SMTPMailer(
            host: "smtp.mailgun.org",
            port: 465,
            securityLayer: .tls(nil),
            credentials: credentials
        )
    }
}

/// To avoid forcing users to deal with an optional on mailer 
/// which would be annoying long term, this is a place holder
/// that simply throws, but provides info on how to setup
/// a proper mailer in the error
final class UnimplementedMailer: MailProtocol {
    func send(_ mail: Email) throws {
        throw MailerError.unimplemented
    }
}

enum MailerError: Debuggable {
    case unimplemented
}

extension MailerError {
    var identifier: String {
        return "unimplemented"
    }

    var reason: String {
        return "mailer hasn't been setup yet"
    }

    var possibleCauses: [String] {
        return [
            "a mailer hasn't been setup yet on droplet"
        ]
    }

    var suggestedFixes: [String] {
        return [
            "add a mailer to your droplet, for example `drop.mailer = SMTPMailer.makeGmail(with: creds)`"
        ]
    }
}
