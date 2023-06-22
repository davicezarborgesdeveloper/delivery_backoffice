import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:validatorless/validatorless.dart';

import '../../../core/env/env.dart';
import '../../../core/extensions/formatter_extensions.dart';
import '../../../core/ui/helpers/loader.dart';
import '../../../core/ui/helpers/messages.dart';
import '../../../core/ui/helpers/size_extensions.dart';
import '../../../core/ui/helpers/upload_html_helper.dart';
import '../../../core/ui/styles/text_styles.dart';
import 'product_detail_controller.dart';

class ProductDetailPage extends StatefulWidget {
  final int? productId;

  const ProductDetailPage({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with Loader, Messages {
  final controller = Modular.get<ProductDetailController>();
  final formKey = GlobalKey<FormState>();
  final nameEC = TextEditingController();
  final priceEC = TextEditingController();
  final descriptionEC = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reaction((_) => controller.status, (status) {
        switch (status) {
          case ProductDetailStateStatus.initial:
            break;
          case ProductDetailStateStatus.loading:
            showLoader();
            break;
          case ProductDetailStateStatus.loaded:
            final model = controller.productModel!;
            nameEC.text = model.name;
            priceEC.text = model.price.currencyPTBR;
            descriptionEC.text = model.description;
            hideLoader();
            break;
          case ProductDetailStateStatus.error:
            hideLoader();
            showError(controller.errorMessage!);
            break;
          case ProductDetailStateStatus.errorLoadProduct:
            hideLoader();
            showError('Erro ao carregar o produto para alteração');
            Navigator.of(context).pop();
            break;
          case ProductDetailStateStatus.uploaded:
            hideLoader();
            break;
          case ProductDetailStateStatus.deleted:
          case ProductDetailStateStatus.saved:
            hideLoader();
            Navigator.pop(context);
            break;
        }
      });
      controller.loadProduct(widget.productId);
    });
    super.initState();
  }

  @override
  void dispose() {
    nameEC.dispose();
    priceEC.dispose();
    descriptionEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widthbuttonAction = context.percentWidth(.4);
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.productId != null ? 'Alterar' : 'Adicionar'} Produto',
                      textAlign: TextAlign.center,
                      style: context.textStyles.textTitle.copyWith(
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Observer(
                        builder: (_) {
                          if (controller.imagePath != null) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                '${Env.instance.get('backend_base_url')}${controller.imagePath}',
                                width: 200,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: TextButton(
                          onPressed: () {
                            UploadHtmlHelper()
                                .startUpload(controller.uploadImageProduct);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                          ),
                          child: Observer(
                            builder: (context) {
                              return Text(
                                '${controller.imagePath == null ? 'Adicionar' : 'Alterar'} Foto',
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameEC,
                          decoration: const InputDecoration(
                            label: Text('Nome'),
                          ),
                          validator: Validatorless.required('Nome obrigatório'),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: priceEC,
                          decoration: const InputDecoration(
                            label: Text('Preço'),
                          ),
                          validator:
                              Validatorless.required('Preço obrigatório'),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CentavosInputFormatter(moeda: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: descriptionEC,
                maxLines: null,
                minLines: 10,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  label: Text('Descrição'),
                  alignLabelWithHint: true,
                ),
                validator: Validatorless.required('Descrição obrigatória'),
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: widthbuttonAction,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        width: widthbuttonAction / 2,
                        height: 60,
                        child: Visibility(
                          visible: widget.productId != null,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Confirmar'),
                                    content: Text(
                                      'Confirme a exclusão do produto ${controller.productModel!.name}',
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          'Cancelar',
                                          style: context.textStyles.textBold
                                              .copyWith(color: Colors.red),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text(
                                          'Confirmar',
                                          style: context.textStyles.textBold,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          controller.deleteProduct();
                                        },
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                            child: Text(
                              'Deletar',
                              style: context.textStyles.textBold
                                  .copyWith(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        width: widthbuttonAction / 2,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            final valid =
                                formKey.currentState?.validate() ?? false;
                            if (valid) {
                              if (controller.imagePath == null) {
                                showWarning(
                                  'Imagem obrigatória, por favor clique em adicionar foto',
                                );
                                return;
                              }
                              controller.save(
                                nameEC.text,
                                UtilBrasilFields.converterMoedaParaDouble(
                                  priceEC.text,
                                ),
                                descriptionEC.text,
                              );
                            }
                          },
                          child: Text(
                            'Salvar',
                            style: context.textStyles.textBold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
