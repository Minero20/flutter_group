import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';

// Events
abstract class ProductEvent {}

class FetchProducts extends ProductEvent {}

// States
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;

  ProductLoaded({required this.products});
}

class ProductError extends ProductState {
  final String message;

  ProductError({required this.message});
}

// BLoC
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc({required this.id, required this.name, required this.price}) : ;

  final ProductService productService = ProductService();

  @override
  ProductState get initialState => ProductInitial();

  @override
  Stream<ProductState> mapEventToState(ProductEvent event) async* {
    if (event is FetchProducts) {
      yield ProductLoading();
      try {
        List<Product> products = await productService.getProducts();
        yield ProductLoaded(products: products);
      } catch (e) {
        yield ProductError(message: 'Failed to load products');
      }
    }
  }
}
