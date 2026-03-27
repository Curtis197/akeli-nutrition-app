import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_web_view.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'cgu_model.dart';
export 'cgu_model.dart';

class CguWidget extends StatefulWidget {
  const CguWidget({super.key});

  static String routeName = 'CGU';
  static String routePath = '/cgu';

  @override
  State<CguWidget> createState() => _CguWidgetState();
}

class _CguWidgetState extends State<CguWidget> {
  late CguModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CguModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'CGU'});
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).secondaryBackground,
              size: 30.0,
            ),
            onPressed: () async {
              logFirebaseEvent('CGU_PAGE_arrow_back_rounded_ICN_ON_TAP');
              logFirebaseEvent('IconButton_navigate_back');
              context.pop();
            },
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: FlutterFlowWebView(
                  content:
                      '<!DOCTYPE html>\n<html lang=\"fr\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\">\n    <title>Conditions Générales d\'Utilisation - Akeli</title>\n    <style>\n        * {\n            margin: 0;\n            padding: 0;\n            box-sizing: border-box;\n            -webkit-tap-highlight-color: transparent;\n        }\n        \n        body {\n            font-family: -apple-system, BlinkMacSystemFont, \'Segoe UI\', Roboto, \'Helvetica Neue\', Arial, sans-serif;\n            line-height: 1.6;\n            color: #1a1a1a;\n            background-color: #ffffff;\n            padding: 20px;\n            font-size: 16px;\n        }\n        \n        .header {\n            text-align: center;\n            padding-bottom: 20px;\n            margin-bottom: 30px;\n            border-bottom: 2px solid #f0f0f0;\n        }\n        \n        .logo {\n            font-size: 28px;\n            font-weight: 700;\n            color: #2c3e50;\n            margin-bottom: 8px;\n        }\n        \n        .doc-title {\n            font-size: 22px;\n            font-weight: 600;\n            color: #2c3e50;\n            margin-bottom: 8px;\n        }\n        \n        .doc-date {\n            font-size: 13px;\n            color: #7f8c8d;\n            font-style: italic;\n        }\n        \n        .section {\n            margin-bottom: 30px;\n        }\n        \n        h2 {\n            font-size: 18px;\n            font-weight: 600;\n            color: #2c3e50;\n            margin-bottom: 12px;\n            padding-top: 10px;\n        }\n        \n        h3 {\n            font-size: 16px;\n            font-weight: 600;\n            color: #34495e;\n            margin-top: 20px;\n            margin-bottom: 10px;\n        }\n        \n        p {\n            margin-bottom: 12px;\n            font-size: 15px;\n            line-height: 1.6;\n        }\n        \n        strong {\n            font-weight: 600;\n            color: #2c3e50;\n        }\n        \n        .highlight-box {\n            background-color: #fff3cd;\n            border-left: 4px solid #ffc107;\n            padding: 15px;\n            margin: 15px 0;\n            border-radius: 4px;\n        }\n        \n        .highlight-box p {\n            margin-bottom: 8px;\n        }\n        \n        .info-box {\n            background-color: #e7f3ff;\n            border-left: 4px solid #2196f3;\n            padding: 15px;\n            margin: 15px 0;\n            border-radius: 4px;\n        }\n        \n        .info-box p {\n            margin-bottom: 8px;\n        }\n        \n        .warning-box {\n            background-color: #ffebee;\n            border-left: 4px solid #f44336;\n            padding: 15px;\n            margin: 15px 0;\n            border-radius: 4px;\n        }\n        \n        .warning-box p {\n            margin-bottom: 8px;\n        }\n        \n        ul, ol {\n            margin-left: 20px;\n            margin-bottom: 12px;\n        }\n        \n        li {\n            margin-bottom: 8px;\n            font-size: 15px;\n        }\n        \n        .summary {\n            background-color: #f8f9fa;\n            padding: 15px;\n            border-radius: 8px;\n            margin-bottom: 25px;\n        }\n        \n        .summary h3 {\n            margin-top: 0;\n            font-size: 17px;\n            color: #2c3e50;\n        }\n        \n        .summary ul {\n            margin-top: 10px;\n        }\n        \n        .contact-box {\n            background-color: #f8f9fa;\n            padding: 15px;\n            border-radius: 8px;\n            text-align: center;\n            margin-top: 30px;\n        }\n        \n        .contact-box p {\n            margin-bottom: 5px;\n        }\n        \n        a {\n            color: #2196f3;\n            text-decoration: none;\n        }\n        \n        a:active {\n            opacity: 0.7;\n        }\n        \n        .footer {\n            margin-top: 40px;\n            padding-top: 20px;\n            border-top: 2px solid #f0f0f0;\n            text-align: center;\n            font-size: 13px;\n            color: #7f8c8d;\n        }\n    </style>\n</head>\n<body>\n    <div class=\"header\">\n        <div class=\"logo\">Akeli</div>\n        <h1 class=\"doc-title\">Conditions Générales<br>d\'Utilisation</h1>\n        <p class=\"doc-date\">En vigueur au 28 octobre 2025</p>\n    </div>\n\n    <div class=\"summary\">\n        <h3>📋 Résumé rapide</h3>\n        <ul>\n            <li>✅ Essai gratuit de <strong>7 jours</strong></li>\n            <li>💳 Abonnement : <strong>4,99€/mois</strong></li>\n            <li>🔄 Résiliation <strong>gratuite</strong> à tout moment</li>\n            <li>⚠️ Les recommandations IA sont <strong>informatives uniquement</strong></li>\n            <li>❌ Aucun remboursement pour le moment</li>\n        </ul>\n    </div>\n\n    <div class=\"section\">\n        <h2>PRÉAMBULE</h2>\n        <p>Les présentes Conditions Générales d\'Utilisation (CGU) régissent l\'utilisation de l\'application mobile Akeli, éditée par Jean-Philippe CAPRE, entrepreneur individuel.</p>\n        <p>Akeli est un service de planification de repas utilisant l\'intelligence artificielle, spécialisé dans la cuisine africaine.</p>\n    </div>\n\n    <div class=\"section\">\n        <h2>1. ACCEPTATION DES CGU</h2>\n        <p>En utilisant l\'application Akeli, vous acceptez sans réserve les présentes CGU.</p>\n        <p>Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.</p>\n    </div>\n\n    <div class=\"section\">\n        <h2>2. ACCÈS À L\'APPLICATION</h2>\n        <p>L\'application est accessible aux personnes majeures disposant d\'un smartphone compatible et d\'une connexion Internet.</p>\n        <p>Vous êtes responsable de la confidentialité de vos identifiants de connexion.</p>\n    </div>\n\n    <div class=\"section\">\n        <h2>3. SERVICES ET TARIFS</h2>\n        \n        <h3>3.1 Période d\'essai gratuite</h3>\n        <div class=\"info-box\">\n            <p><strong>7 jours d\'essai gratuit</strong> avec accès à toutes les fonctionnalités premium.</p>\n        </div>\n\n        <h3>3.2 Abonnement mensuel</h3>\n        <div class=\"info-box\">\n            <p><strong>Prix : 4,99€ TTC/mois</strong></p>\n            <p>Renouvellement automatique chaque mois.</p>\n            <p>Le premier paiement intervient après la période d\'essai de 7 jours.</p>\n        </div>\n\n        <h3>3.3 Fonctionnalités</h3>\n        <ul>\n            <li>Plans de repas personnalisés par IA</li>\n            <li>Recommandations adaptées à vos objectifs</li>\n            <li>Recettes de cuisine africaine</li>\n            <li>Gestion des allergies et préférences</li>\n            <li>Outils de planification</li>\n        </ul>\n\n        <div class=\"warning-box\">\n            <p><strong>⚠️ Important :</strong> Les recommandations de l\'IA sont fournies à titre indicatif uniquement. Elles ne constituent pas un avis médical ou nutritionnel. En cas d\'allergies graves, consultez un professionnel de santé.</p>\n        </div>\n    </div>\n\n    <div class=\"section\">\n        <h2>4. PAIEMENT</h2>\n        <p>Le paiement s\'effectue par carte bancaire via <strong>Stripe</strong>, notre prestataire de paiement sécurisé.</p>\n        <p>Une facture est disponible pour chaque paiement dans votre compte.</p>\n\n        <h3>4.1 Politique de remboursement</h3>\n        <div class=\"highlight-box\">\n            <p><strong>Aucun remboursement n\'est accordé pour le moment</strong>, même en cas de non-utilisation du service.</p>\n            <p>Vous pouvez toutefois résilier votre abonnement à tout moment pour éviter les prélèvements futurs.</p>\n        </div>\n    </div>\n\n    <div class=\"section\">\n        <h2>5. RÉSILIATION</h2>\n        \n        <h3>5.1 Comment résilier ?</h3>\n        <p>Vous pouvez résilier votre abonnement <strong>gratuitement et à tout moment</strong> directement dans l\'application :</p>\n        <ol>\n            <li>Accédez aux <strong>Paramètres</strong></li>\n            <li>Cliquez sur <strong>\"Gérer mon abonnement\"</strong></li>\n            <li>Suivez les 3 étapes de résiliation</li>\n        </ol>\n\n        <div class=\"info-box\">\n            <p><strong>Après résiliation :</strong></p>\n            <ul>\n                <li>✅ Vous gardez l\'accès jusqu\'à la fin de la période payée</li>\n                <li>❌ Aucun prélèvement futur ne sera effectué</li>\n                <li>📧 Vous recevrez une confirmation par email</li>\n            </ul>\n        </div>\n    </div>\n\n    <div class=\"section\">\n        <h2>6. VOS OBLIGATIONS</h2>\n        <p>En utilisant Akeli, vous vous engagez à :</p>\n        <ul>\n            <li>Fournir des informations exactes</li>\n            <li>Protéger vos identifiants</li>\n            <li>Utiliser l\'application de manière conforme</li>\n            <li>Ne pas tenter de contourner les mesures de sécurité</li>\n            <li>Ne pas copier ou revendre l\'application</li>\n        </ul>\n    </div>\n\n    <div class=\"section\">\n        <h2>7. PROPRIÉTÉ INTELLECTUELLE</h2>\n        <p>L\'application Akeli, son contenu et ses fonctionnalités sont la propriété exclusive de Jean-Philippe CAPRE.</p>\n        <p>Vous disposez d\'une licence personnelle, non-exclusive et révocable pour utiliser l\'application à des fins personnelles uniquement.</p>\n    </div>\n\n    <div class=\"section\">\n        <h2>8. DONNÉES PERSONNELLES</h2>\n        <p>La collecte et le traitement de vos données sont régis par notre <a href=\"#\">Politique de Confidentialité</a>.</p>\n        <p>Nous collectons : nom, email, préférences alimentaires, objectifs, allergies, poids, âge.</p>\n        <p>Conformément au RGPD, vous disposez d\'un droit d\'accès, de rectification, de suppression et de portabilité de vos données.</p>\n        <p><strong>Contact :</strong> legal@akeli.app</p>\n    </div>\n\n    <div class=\"section\">\n        <h2>9. RESPONSABILITÉ</h2>\n        \n        <h3>9.1 Disponibilité du service</h3>\n        <p>Nous faisons notre maximum pour assurer la disponibilité de l\'application 24h/24, mais ne pouvons garantir une disponibilité absolue.</p>\n\n        <h3>9.2 Recommandations IA</h3>\n        <div class=\"warning-box\">\n            <p><strong>Nous ne sommes pas responsables :</strong></p>\n            <ul>\n                <li>De l\'inexactitude des recommandations générées</li>\n                <li>Des réactions allergiques</li>\n                <li>De l\'atteinte ou non de vos objectifs de santé</li>\n            </ul>\n            <p><strong>L\'application ne remplace pas l\'avis d\'un médecin ou nutritionniste.</strong></p>\n        </div>\n\n        <h3>9.3 Limitation de responsabilité</h3>\n        <p>Notre responsabilité est limitée au montant total des sommes que vous avez versées au cours des 12 derniers mois.</p>\n    </div>\n\n    <div class=\"section\">\n        <h2>10. DROIT DE RÉTRACTATION</h2>\n        <p>Vous disposez d\'un délai de <strong>14 jours</strong> pour exercer votre droit de rétractation.</p>\n        <p>Toutefois, en utilisant l\'application pendant la période d\'essai, vous reconnaissez que le service commence immédiatement et acceptez de perdre ce droit de rétractation.</p>\n        <p>La période d\'essai gratuite de 7 jours vous permet de tester toutes les fonctionnalités avant tout engagement financier.</p>\n    </div>\n\n    <div class=\"section\">\n        <h2>11. MODIFICATIONS DES CGU</h2>\n        <p>Nous pouvons modifier ces CGU à tout moment. Vous serez informé des modifications importantes par notification dans l\'application ou par email.</p>\n        <p>L\'utilisation continue de l\'application après modification vaut acceptation des nouvelles CGU.</p>\n    </div>\n\n    <div class=\"section\">\n        <h2>12. MÉDIATION ET LITIGES</h2>\n        <p>En cas de litige, vous pouvez recourir gratuitement à un médiateur de la consommation :</p>\n        <div class=\"info-box\">\n            <p><strong>Centre de Médiation et de Règlement Amiable (CMAP)</strong></p>\n            <p>39 avenue Franklin D. Roosevelt<br>75008 Paris</p>\n            <p>Email : conso@cmap.fr<br>\n            Site : <a href=\"https://www.cmap.fr\">www.cmap.fr</a></p>\n        </div>\n        <p>Les présentes CGU sont régies par le droit français.</p>\n    </div>\n\n    <div class=\"contact-box\">\n        <p><strong>Des questions ?</strong></p>\n        <p>📧 <a href=\"mailto:legal@akeli.app\">legal@akeli.app</a></p>\n        <p style=\"margin-top: 10px; font-size: 14px;\">Jean-Philippe CAPRE<br>Entrepreneur Individuel<br>France</p>\n    </div>\n\n    <div class=\"footer\">\n        <p>© 2025 Akeli - Tous droits réservés</p>\n        <p style=\"margin-top: 10px;\">\n            <a href=\"#\">Mentions Légales</a> | \n            <a href=\"#\">Politique de Confidentialité</a>\n        </p>\n    </div>\n</body>\n</html>',
                  height: MediaQuery.sizeOf(context).height * 0.87,
                  verticalScroll: false,
                  horizontalScroll: false,
                  html: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
