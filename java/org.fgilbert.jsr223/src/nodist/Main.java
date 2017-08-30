package nodist;

/// clean up this file

import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import org.fgilbert.jdx.*;
import org.fgilbert.jsr223.Controller;

class Main {

	public static void mainXSF(String[] args) {
//		Integer[][][][][] array = {{{{{null, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}}, {{{0, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}}, {{{0, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, null}}}}, {{{{null, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}}, {{{0, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}}, {{{0, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, null}}}}};
//		Integer[][][] array = {{{0, 1, 2}, {0, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}};
//		int[][][] array = {{{1,2,3},{4,5,6},{7,8,9}},{{10,11,12},{13,14,15},{16,17,18}},{{19,20,21},{22,23,24},{25,26,27}}};
//		int[][][] array = {{{1,10,19},{4,13,22},{7,16,25}},{{2,11,20},{5,14,23},{8,17,26}},{{3,12,21},{6,15,24},{9,18,27}}};
//		int[][][] array = {{{1, 4, 7}, {2, 5, 8}, {3, 6, 9}}, {{10, 13, 16}, {11, 14, 17}, {12, 15, 18}}, {{19, 22, 25}, {20, 23, 26}, {21, 24, 27}}};
//		JavaToR j2r = new JavaToR(array, ArrayOrder.ROW_MAJOR_JAVA);
//		Object[] r = j2r.getValueObjectArray1d();
//		System.out.println(r.length);
//		j2r = new JavaToR(new String[][] {{}}, ArrayOrder.COLUMN_MAJOR);
//		j2r = new JavaToR(new String[][] {}, ArrayOrder.ROW_MAJOR);
//		j2r = new JavaToR(new String[][] {}, ArrayOrder.ROW_MAJOR_JAVA);
//		JavaToR j2r = new JavaToR(new int[][] {{}}, ArrayOrder.ROW_MAJOR);
//		Object[] r = j2r.getValueObjectArray1d();
//		System.out.println(r.length);
//		Object o = new int[] {};
//		System.out.println(o.getClass().getName());
		
//		data = new int[] {1, 4, 2, 5, 3, 6, 7, 10, 8, 11, 9, 12, 13, 16, 14, 17, 15, 18};
//		dimensions = new int[] {3, 2, 3};
//		Object[] arrayExpected = new int[][][] {{{1, 2, 3}, {4, 5, 6}}, {{7, 8, 9}, {10, 11, 12}}, {{13, 14, 15}, {16, 17, 18}}};
//		Object[] arrayActual = (int[][][]) Utility.createNdimensionalArrayRowMajorJava(data, dimensions); 
//		assertArrayEquals(arrayExpected, arrayActual);
//
//		data = new int[] {1, 3, 5, 2, 4, 6, 7, 9, 11, 8, 10, 12, 13, 15, 17, 14, 16, 18};
//		dimensions = new int[] {3, 3, 2};
//		arrayExpected = new int[][][] {{{1, 2}, {3, 4}, {5, 6}}, {{7, 8}, {9, 10}, {11, 12}}, {{13, 14}, {15, 16}, {17, 18}}};
//		arrayActual = (Object[]) Utility.createNdimensionalArrayRowMajorJava(data, dimensions); 
//		assertArrayEquals(arrayExpected, arrayActual);
		
//		int[] data;
//		data = new int[] {1, 4, 2, 5, 3, 6, 7, 10, 8, 11, 9, 12, 13, 16, 14, 17, 15, 18};
//		int[] dimensions;
//		dimensions = new int[] {3, 2, 3};
//		int[][][] nnn = (int[][][]) Utility.createNdimensionalArrayRowMajorJava(data, dimensions);
//		System.out.println(nnn.length);
//		Object o;
//		o = java.util.Arrays.asList(nnn);
//		System.out.println(nnn.length);

//		int[] data;
//		data = new int[] {1, 4, 7, 2, 5, 8, 3, 6, 9};
//		int[] dimensions;
//		dimensions = new int[] {3, 3};
//		int[][] nn = (int[][]) Utility.createNdimensionalArrayRowMajorJava(data, dimensions);
//		Object o = java.util.Arrays.asList(nn);
//		JavaToR j2r = new JavaToR(o); 
//		System.out.println(j2r.getRdataCompositeCode());
//		data = new int[] {1, 4, 2, 5, 3, 6, 7, 10, 8, 11, 9, 12, 13, 16, 14, 17, 15, 18};
//		dimensions = new int[] {3, 2, 3};
//		int[][][] nnn = (int[][][]) Utility.createNdimensionalArrayRowMajorJava(data, dimensions);
//		o = java.util.Arrays.asList(nnn);
//		j2r = new JavaToR(o);
//		System.out.println(j2r.getRdataCompositeCode());
		
		int[] data;
		data = new int[] {1, 4, 2, 5, 3, 6, 7, 10, 8, 11, 9, 12, 13, 16, 14, 17, 15, 18, 1, 4, 2, 5, 3, 6, 7, 10, 8, 11, 9, 12, 13, 16, 14, 17, 15, 18};
		int[] dimensions;
		dimensions = new int[] {2, 3, 2, 3};
		int[][][][] n = (int[][][][]) Utility.createNdimensionalArrayRowMajorJava(data, dimensions);
		ArrayList<Object> al1 = new ArrayList();
		for (int i = 0; i < dimensions[0]; i++) {
			ArrayList<Object> al2 = new ArrayList();
			for (int j = 0; j < dimensions[1]; j++) {
				ArrayList<Object> al3 = new ArrayList();
				for (int k = 0; k < dimensions[2]; k++) {
					ArrayList<Object> al4 = new ArrayList();
					for (int l = 0; l < dimensions[3]; l++) {
						al4.add(n[i][j][k][l]);
					}
					al3.add(al4);
				}
				al2.add(al3);
			}
			al1.add(al2);
		}
		JavaToR j2r = new JavaToR(al1);
		System.out.println(j2r.getRdataCompositeCode());
	}
	
	public static void mainIOI(String[] args) {
		int iterations = 1000000;
		int[] data1 = new int[2000];
		int[] data2 = new int[data1.length * 2];
		final long startTime = System.currentTimeMillis();
//		int k = 0;
		for (int i = 0; i < iterations; i++) {
//		  System.arraycopy(data1, 0, data2, data1.length, data1.length);
			for (int j = 0; j < data1.length; j++)
				data2[j] = data1[j];
		}
		final long endTime = System.currentTimeMillis();
		System.out.println("Total execution time: " + (endTime - startTime) );		
	}
	
	public static int[] oneD() {
		int[] n = {1, 2, 3};
		return n;
	}
	
	public static int[][] twoD() {
		int[][] n = {{1, 2, 3}, {4, 5, 6}};
//		int[][] n = {{1}};
		return n;
	}
	
	public static int[][][] threeD() {
		int[][][] n = {{{1, 2, 3}, {4, 5, 6}}, {{1, 2, 3}, {4, 5, 6}}};
		return n;
	}
	
	public static int getNumberOfDimensions(Class<?> type) {
		int n = -1;
		do {
			type = type.getComponentType();
			n++;
		} while (type != null);
		return n;
    }
	
	public static void mainXI(String[] args) {
//		int[] n = oneD();
//		int[][] nn = twoD();
//		int[][][] nnn = threeD();
//		//java.util.ArrayList<int[]> c = Array.newInstance(componentType, dimensions);
//		n = Arrays.stream(nn).flatMapToInt(Arrays::stream).toArray();
//		System.out.println(Arrays.toString(n));		
//		n = Arrays.stream(nnn).flatMapToInt(Arrays::stream).toArray();
//		System.out.println(Arrays.toString(n));		
		return;
	}

	
	public static Integer[] flatten(Object[] inputArray) throws IllegalArgumentException {

        if (inputArray == null) return null;

        List<Integer> flatList = new ArrayList<Integer>();

        for (Object element : inputArray) {
            if (element instanceof Integer) {
                flatList.add((Integer) element);
            } else if (element instanceof Object[]) {
                flatList.addAll(Arrays.asList(flatten((Object[]) element)));
            } else {
                throw new IllegalArgumentException("Input must be an array of Integers or nested arrays of Integers");
            }
        }
        return flatList.toArray(new Integer[flatList.size()]);
    }
	
	public static void main(String[] args) {
//		int[][] nn = twoD();
//		Object oo = Utility.deepAsList(nn);
		Object oo = Utility.deepAsList(new Integer[][] {{}});
		return;
	}
	
	public static void mainRWR(String[] args) {
//		Object o = Utility.createNdimensionalArray(new int[] {1, 2, 3, 4}, new int[] {2, 2}, false);
		int max = 2000;
		int[] data = new int[max];
		int[] data2 = new int[max];
		double[] data3 = new double[max];
		for (int i = 0; i < max; i++)
			data[i] = i + 1;
//		int[] dimensions = new int[] {1, 1, 0};
//		Object o = Utility.createNdimensionalArrayRowMajor(data, dimensions);
//		o = Utility.createNdimensionalArrayColumnMajor(data, dimensions);
		final long startTime = System.currentTimeMillis();
		int iterations = 100000;
		for (int i = 0; i < iterations; i++) {
//			data3 = Arrays.stream(data).asDoubleStream().toArray();
			for (int j = 0; j < data.length; j++) {
				data3[j] = (double) data[j];
//				data3[j] = Array.getDouble(data, j);
			}
		}
		final long endTime = System.currentTimeMillis();
		System.out.println("Total execution time: " + (endTime - startTime) );		
		return;
	}
	
	public static void mainDXD(String[] args) {
		Controller controller = null;
		try {
			controller = new Controller("js");
//			controller.putEvaluationRequest("var a = [[1,null],[2,'b']];", true);
//			controller.putEvaluationRequest("var ArrayListClass = Java.type('java.util.ArrayList');var a = new ArrayListClass();var LinkedHashMapClass = Java.type('java.util.LinkedHashMap');var m = new LinkedHashMapClass();m.put('a', 'a');m.put('b', 2);a.add(m);", true);
//			controller.putEvaluationRequest("var ArrayListClass = Java.type('java.util.ArrayList');", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("var LinkedHashMapClass = Java.type('java.util.LinkedHashMap');", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("var a = new ArrayListClass(2)", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("var m = new LinkedHashMapClass();", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("m.put('a', 3); m.put('b', 2); a.add(m);", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("m = new LinkedHashMapClass();", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("m.put('a', null); m.put('b', 2); a.add(m);", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
//			controller.setArrayOrder(org.fgilbert.jdx.JavaToR.ArrayOrder.ROW_MAJOR);
			controller.setArrayOrder(org.fgilbert.jdx.JavaToR.ArrayOrder.COLUMN_MAJOR);
//			int iterations = 50000;
//			final long startTime = System.currentTimeMillis();
//			for (int i = 0; i < iterations; i++) {
//			controller.putEvaluationRequest("var value = [[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12]], [[13, 14, 15, 16], [17, 18, 19, 20], [21, 22, 23, 24]]]", true);
//			controller.putEvaluationRequest("eval('[[1., 5, 9], [2, 6, 10], [3, 7, 11], [4, 8, 12]]')", false);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
			controller.putEvaluationRequest("var a = new java.lang.Byte(1);", false);
			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
			controller.putEvaluationRequest("var b = [a, a, a];", false);
			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
			controller.putEvaluationRequest("var c = [1, 2, 3];", false);
			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
			controller.putEvaluationRequest("[[b], [c]];", false);
			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
//			controller.putEvaluationRequest("", false);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
//			int typeCode = controller.getScriptEngineValue("value");
//			}
//			final long endTime = System.currentTimeMillis();
			JavaToR j2r = controller.getResponse();
			Object[] o = j2r.getValueObjectArray1d();
			o = j2r.getValueObjectArray1d();
//			System.out.println("Total execution time: " + (endTime - startTime) );		
//			controller.setArrayOrder(org.fgilbert.jdx.JavaToR.ArrayOrder.COLUMN_MAJOR);
//			controller.putEvaluationRequest("var value = [[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12]], [[13, 14, 15, 16], [17, 18, 19, 20], [21, 22, 23, 24]]]", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
//			controller.setScriptEngineValue("a", new boolean[] {});
//			JavaToR j2r = controller.getResponse();
//			int typeCode = controller.getScriptEngineValue("value");
//			System.out.println(String.format("%X", typeCode));
//			Object o = controller.getResponse().getValueObject();
//			System.out.println(String.format("%X", typeCode));
//			System.out.println(controller.getScriptEngineValueClassName("a"));
//			System.out.println(controller.getResponseInteger());
//			controller.putEvaluationRequest("true;", false);
//			typeCode = controller.waitForEvaluation();
//			System.out.println(typeCode);
//			System.out.println(controller.getResponseBoolean());
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if (controller != null)
				try {
					controller.terminate();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
		}
	}
}
